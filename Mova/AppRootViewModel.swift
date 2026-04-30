import Combine
import Foundation

@MainActor
final class AppRootViewModel: ObservableObject {
    @Published var serverAddress = ""
    @Published var serverUsername = ""
    @Published var serverTokenType = "Bearer"
    @Published var serverTokenExpiresAt = ""
    @Published var serverValidated = false

    @Published var isLoading = false
    @Published var alertMessage: String?
    @Published var hasServerToken = false
    @Published var libraries: [LibrarySummary] = []
    @Published var mediaItems: [MediaItemSummary] = []
    @Published var libraryPreviewItems: [Int: [MediaItemSummary]] = [:]
    @Published var libraryItemsByID: [Int: [MediaItemSummary]] = [:]
    @Published var libraryStatsByID: [Int: LibraryStats] = [:]
    @Published var selectedLibraryID: Int?
    @Published var isHomeLoading = false

    private var sessionChecked = false
    private let defaults = UserDefaults.standard
    private let authService = AuthService()
    private let mediaService = MediaService()

    init() {
        loadStoredState()
        hasServerToken = KeychainTokenStore.shared.readToken() != nil
    }

    var hasServerInfo: Bool {
        !serverAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasAnySource: Bool {
        hasServerInfo
    }

    var hasValidatedServer: Bool {
        hasServerInfo && serverValidated && hasServerToken
    }

    func restoreSessionIfNeeded() async {
        guard !sessionChecked else { return }
        sessionChecked = true

        guard hasServerInfo, serverValidated,
              let token = KeychainTokenStore.shared.readToken() else {
            hasServerToken = false
            return
        }

        if isTokenExpired(isoTimestamp: serverTokenExpiresAt) {
            clearServerSession()
            return
        }

        guard let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            clearServerSession()
            return
        }

        do {
            try await authService.checkCurrentSession(baseURL: baseURL, token: token)
            hasServerToken = true
            await loadHomeData()
        } catch {
            clearServerSession()
        }
    }

    func loginWithServer(address: String, username: String, password: String) async {
        guard let baseURL = authService.normalizeBaseURL(from: address) else {
            alertMessage = AuthFlowError.invalidURL.localizedDescription
            return
        }

        isLoading = true

        do {
            try await authService.checkHealth(baseURL: baseURL)
            let tokenResponse = try await authService.tokenLogin(baseURL: baseURL, username: username, password: password)
            try KeychainTokenStore.shared.saveToken(tokenResponse.token)

            serverAddress = baseURL.absoluteString
            serverUsername = username
            serverTokenType = tokenResponse.tokenType ?? "Bearer"
            serverTokenExpiresAt = tokenResponse.expiresAt ?? ""
            serverValidated = true
            hasServerToken = true
            persistState()
            await loadHomeData()
        } catch {
            clearServerSession()
            alertMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteServer() {
        clearServerSession(removeServerInfo: true)
    }

    func loadHomeData() async {
        guard hasValidatedServer,
              let token = KeychainTokenStore.shared.readToken(),
              let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            return
        }

        isHomeLoading = true

        do {
            let fetchedLibraries = try await mediaService.fetchLibraries(
                baseURL: baseURL,
                token: token,
                tokenType: serverTokenType
            )
            libraries = fetchedLibraries

            var previewMap: [Int: [MediaItemSummary]] = [:]
            var allItemsMap: [Int: [MediaItemSummary]] = [:]
            var statsMap: [Int: LibraryStats] = [:]

            try await withThrowingTaskGroup(of: (Int, [MediaItemSummary], LibraryStats).self) { group in
                for library in fetchedLibraries {
                    group.addTask {
                        let allItems = try await self.mediaService.fetchAllMediaItems(
                            baseURL: baseURL,
                            token: token,
                            tokenType: self.serverTokenType,
                            libraryID: library.id
                        )
                        let movieCount = allItems.filter { $0.mediaType == "movie" }.count
                        let seriesCount = allItems.filter { $0.mediaType == "series" }.count
                        let stats = LibraryStats(total: allItems.count, movieCount: movieCount, seriesCount: seriesCount)
                        return (library.id, allItems, stats)
                    }
                }

                for try await (libraryID, items, stats) in group {
                    previewMap[libraryID] = Array(items.prefix(16))
                    allItemsMap[libraryID] = items
                    statsMap[libraryID] = stats
                }
            }

            libraryPreviewItems = previewMap
            libraryItemsByID = allItemsMap
            libraryStatsByID = statsMap

            let preferredLibraryID: Int?
            if let selectedLibraryID, fetchedLibraries.contains(where: { $0.id == selectedLibraryID }) {
                preferredLibraryID = selectedLibraryID
            } else {
                preferredLibraryID = fetchedLibraries.first?.id
            }
            selectedLibraryID = preferredLibraryID

            if let libraryID = preferredLibraryID {
                mediaItems = allItemsMap[libraryID] ?? []
            } else {
                mediaItems = []
            }
        } catch {
            if let authError = error as? AuthFlowError,
               case .sessionExpired = authError {
                clearServerSession()
            } else {
                alertMessage = error.localizedDescription
            }
        }

        isHomeLoading = false
    }

    func selectLibrary(_ id: Int) async {
        guard selectedLibraryID != id else { return }
        selectedLibraryID = id
        mediaItems = libraryItemsByID[id] ?? []
    }

    func items(for libraryID: Int) -> [MediaItemSummary] {
        libraryItemsByID[libraryID] ?? []
    }

    func stats(for libraryID: Int) -> LibraryStats? {
        libraryStatsByID[libraryID]
    }

    func imageURL(for path: String?) -> URL? {
        guard let path, !path.isEmpty,
              let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            return nil
        }
        if path.lowercased().hasPrefix("http://") || path.lowercased().hasPrefix("https://") {
            return URL(string: path)
        }
        #if targetEnvironment(simulator)
        if var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
           components.host != "localhost" {
            components.host = "localhost"
            if let localhostBaseURL = components.url {
                return authService.apiURL(baseURL: localhostBaseURL, apiPath: path)
            }
        }
        #endif
        return authService.apiURL(baseURL: baseURL, apiPath: path)
    }

    func imageRequest(for path: String?) -> URLRequest? {
        guard let url = imageURL(for: path),
              let token = KeychainTokenStore.shared.readToken() else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("\(serverTokenType) \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    func loadSeasons(for mediaID: Int) async -> [SeasonSummary] {
        guard let token = KeychainTokenStore.shared.readToken(),
              let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            return []
        }
        do {
            return try await mediaService.fetchSeasons(
                baseURL: baseURL,
                token: token,
                tokenType: serverTokenType,
                mediaID: mediaID
            )
        } catch {
            return []
        }
    }

    func loadEpisodes(for seasonID: Int) async -> [EpisodeSummary] {
        guard let token = KeychainTokenStore.shared.readToken(),
              let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            return []
        }
        do {
            return try await mediaService.fetchEpisodes(
                baseURL: baseURL,
                token: token,
                tokenType: serverTokenType,
                seasonID: seasonID
            )
        } catch {
            return []
        }
    }

    func loadMediaDetail(for mediaID: Int) async throws -> MediaItemDetail {
        guard let token = KeychainTokenStore.shared.readToken() else {
            throw AuthFlowError.sessionExpired
        }
        guard let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            throw AuthFlowError.invalidURL
        }

        return try await mediaService.fetchMediaItemDetail(
            baseURL: baseURL,
            token: token,
            tokenType: serverTokenType,
            mediaID: mediaID
        )
    }

    func loadEpisodeOutline(for mediaID: Int) async throws -> SeriesEpisodeOutline {
        guard let token = KeychainTokenStore.shared.readToken() else {
            throw AuthFlowError.sessionExpired
        }
        guard let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            throw AuthFlowError.invalidURL
        }

        return try await mediaService.fetchEpisodeOutline(
            baseURL: baseURL,
            token: token,
            tokenType: serverTokenType,
            mediaID: mediaID
        )
    }

    func loadCastMembers(for mediaID: Int) async throws -> [MediaCastMember] {
        guard let token = KeychainTokenStore.shared.readToken() else {
            throw AuthFlowError.sessionExpired
        }
        guard let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            throw AuthFlowError.invalidURL
        }

        return try await mediaService.fetchCastMembers(
            baseURL: baseURL,
            token: token,
            tokenType: serverTokenType,
            mediaID: mediaID
        )
    }

    func loadMediaFiles(for mediaID: Int) async throws -> [MediaFileInfo] {
        guard let token = KeychainTokenStore.shared.readToken() else {
            throw AuthFlowError.sessionExpired
        }
        guard let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            throw AuthFlowError.invalidURL
        }

        return try await mediaService.fetchMediaFiles(
            baseURL: baseURL,
            token: token,
            tokenType: serverTokenType,
            mediaID: mediaID
        )
    }

    func loadAudioTracks(for mediaFileID: Int) async throws -> [AudioTrackInfo] {
        guard let token = KeychainTokenStore.shared.readToken() else {
            throw AuthFlowError.sessionExpired
        }
        guard let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            throw AuthFlowError.invalidURL
        }

        return try await mediaService.fetchAudioTracks(
            baseURL: baseURL,
            token: token,
            tokenType: serverTokenType,
            mediaFileID: mediaFileID
        )
    }

    func loadSubtitles(for mediaFileID: Int) async throws -> [SubtitleFileInfo] {
        guard let token = KeychainTokenStore.shared.readToken() else {
            throw AuthFlowError.sessionExpired
        }
        guard let baseURL = authService.normalizeBaseURL(from: serverAddress) else {
            throw AuthFlowError.invalidURL
        }

        return try await mediaService.fetchSubtitles(
            baseURL: baseURL,
            token: token,
            tokenType: serverTokenType,
            mediaFileID: mediaFileID
        )
    }

    func clearAlert() {
        alertMessage = nil
    }

    private func clearServerSession(removeServerInfo: Bool = false) {
        if removeServerInfo {
            serverAddress = ""
            serverUsername = ""
        }

        serverValidated = false
        hasServerToken = false
        serverTokenType = "Bearer"
        serverTokenExpiresAt = ""
        libraries = []
        mediaItems = []
        libraryPreviewItems = [:]
        libraryItemsByID = [:]
        libraryStatsByID = [:]
        selectedLibraryID = nil

        KeychainTokenStore.shared.deleteToken()
        persistState()
    }

    private func loadStoredState() {
        serverAddress = defaults.string(forKey: StorageKeys.serverAddress) ?? ""
        serverUsername = defaults.string(forKey: StorageKeys.serverUsername) ?? ""
        serverTokenType = defaults.string(forKey: StorageKeys.serverTokenType) ?? "Bearer"
        serverTokenExpiresAt = defaults.string(forKey: StorageKeys.serverTokenExpiresAt) ?? ""
        serverValidated = defaults.bool(forKey: StorageKeys.serverValidated)

    }

    private func persistState() {
        defaults.set(serverAddress, forKey: StorageKeys.serverAddress)
        defaults.set(serverUsername, forKey: StorageKeys.serverUsername)
        defaults.set(serverTokenType, forKey: StorageKeys.serverTokenType)
        defaults.set(serverTokenExpiresAt, forKey: StorageKeys.serverTokenExpiresAt)
        defaults.set(serverValidated, forKey: StorageKeys.serverValidated)

    }

    private func isTokenExpired(isoTimestamp: String) -> Bool {
        let trimmed = isoTimestamp.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let formatter = ISO8601DateFormatter()
        guard let expiresAt = formatter.date(from: trimmed) else { return false }
        return expiresAt <= Date()
    }
}

private enum StorageKeys {
    static let serverAddress = "home.serverAddress"
    static let serverUsername = "home.serverUsername"
    static let serverTokenType = "home.serverTokenType"
    static let serverTokenExpiresAt = "home.serverTokenExpiresAt"
    static let serverValidated = "home.serverValidated"
}
