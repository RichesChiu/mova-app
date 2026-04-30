import Foundation

struct MediaService {
    private let authService = AuthService()

    private func decodePayload<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let envelope = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
        guard let payload = envelope.data else {
            throw AuthFlowError.invalidResponse
        }
        return payload
    }

    func fetchLibraries(baseURL: URL, token: String, tokenType: String) async throws -> [LibrarySummary] {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/libraries"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload([LibrarySummary].self, from: data)
    }

    func fetchMediaItems(
        baseURL: URL,
        token: String,
        tokenType: String,
        libraryID: Int,
        pageSize: Int = 20
    ) async throws -> PagedMediaItems {
        let endpoint = authService.apiURL(baseURL: baseURL, apiPath: "/api/libraries/\(libraryID)/media-items")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw AuthFlowError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        guard let url = components.url else {
            throw AuthFlowError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload(PagedMediaItems.self, from: data)
    }

    func fetchAllMediaItems(
        baseURL: URL,
        token: String,
        tokenType: String,
        libraryID: Int
    ) async throws -> [MediaItemSummary] {
        var page = 1
        let pageSize = 100
        var allItems: [MediaItemSummary] = []
        var total = Int.max

        while allItems.count < total {
            let endpoint = authService.apiURL(baseURL: baseURL, apiPath: "/api/libraries/\(libraryID)/media-items")
            guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
                throw AuthFlowError.invalidURL
            }
            components.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
            guard let url = components.url else {
                throw AuthFlowError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 12
            request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await NetworkClient.sharedSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthFlowError.invalidResponse
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw AuthFlowError.sessionExpired
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
            }

            let pageResult = try decodePayload(PagedMediaItems.self, from: data)

            allItems.append(contentsOf: pageResult.items)
            total = pageResult.total
            if pageResult.items.isEmpty { break }
            page += 1
        }

        return allItems
    }

    func fetchMediaItemDetail(
        baseURL: URL,
        token: String,
        tokenType: String,
        mediaID: Int
    ) async throws -> MediaItemDetail {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/media-items/\(mediaID)"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload(MediaItemDetail.self, from: data)
    }

    func fetchEpisodeOutline(
        baseURL: URL,
        token: String,
        tokenType: String,
        mediaID: Int
    ) async throws -> SeriesEpisodeOutline {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/media-items/\(mediaID)/episode-outline"))
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload(SeriesEpisodeOutline.self, from: data)
    }

    func fetchCastMembers(
        baseURL: URL,
        token: String,
        tokenType: String,
        mediaID: Int
    ) async throws -> [MediaCastMember] {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/media-items/\(mediaID)/cast"))
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload([MediaCastMember].self, from: data)
    }

    func fetchMediaFiles(
        baseURL: URL,
        token: String,
        tokenType: String,
        mediaID: Int
    ) async throws -> [MediaFileInfo] {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/media-items/\(mediaID)/files"))
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload([MediaFileInfo].self, from: data)
    }

    func fetchAudioTracks(
        baseURL: URL,
        token: String,
        tokenType: String,
        mediaFileID: Int
    ) async throws -> [AudioTrackInfo] {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/media-files/\(mediaFileID)/audio-tracks"))
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload([AudioTrackInfo].self, from: data)
    }

    func fetchSubtitles(
        baseURL: URL,
        token: String,
        tokenType: String,
        mediaFileID: Int
    ) async throws -> [SubtitleFileInfo] {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/media-files/\(mediaFileID)/subtitles"))
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload([SubtitleFileInfo].self, from: data)
    }

    func fetchSeasons(baseURL: URL, token: String, tokenType: String, mediaID: Int) async throws -> [SeasonSummary] {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/media-items/\(mediaID)/seasons"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload([SeasonSummary].self, from: data)
    }

    func fetchEpisodes(baseURL: URL, token: String, tokenType: String, seasonID: Int) async throws -> [EpisodeSummary] {
        var request = URLRequest(url: authService.apiURL(baseURL: baseURL, apiPath: "/api/seasons/\(seasonID)/episodes"))
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }

        return try decodePayload([EpisodeSummary].self, from: data)
    }
}
