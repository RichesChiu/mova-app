import Foundation

struct MediaService {
    private let authService = AuthService()

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

        if let envelope = try? JSONDecoder().decode(APIEnvelope<[LibrarySummary]>.self, from: data),
           let payload = envelope.data {
            return payload
        }

        if let direct = try? JSONDecoder().decode([LibrarySummary].self, from: data) {
            return direct
        }

        throw AuthFlowError.invalidResponse
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

        if let envelope = try? JSONDecoder().decode(APIEnvelope<PagedMediaItems>.self, from: data),
           let payload = envelope.data {
            return payload
        }

        if let direct = try? JSONDecoder().decode(PagedMediaItems.self, from: data) {
            return direct
        }

        throw AuthFlowError.invalidResponse
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

            let pageResult: PagedMediaItems
            if let envelope = try? JSONDecoder().decode(APIEnvelope<PagedMediaItems>.self, from: data),
               let payload = envelope.data {
                pageResult = payload
            } else if let direct = try? JSONDecoder().decode(PagedMediaItems.self, from: data) {
                pageResult = direct
            } else {
                throw AuthFlowError.invalidResponse
            }

            allItems.append(contentsOf: pageResult.items)
            total = pageResult.total
            if pageResult.items.isEmpty { break }
            page += 1
        }

        return allItems
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

        if let envelope = try? JSONDecoder().decode(APIEnvelope<[SeasonSummary]>.self, from: data),
           let payload = envelope.data {
            return payload
        }
        if let direct = try? JSONDecoder().decode([SeasonSummary].self, from: data) {
            return direct
        }
        throw AuthFlowError.invalidResponse
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

        if let envelope = try? JSONDecoder().decode(APIEnvelope<[EpisodeSummary]>.self, from: data),
           let payload = envelope.data {
            return payload
        }
        if let direct = try? JSONDecoder().decode([EpisodeSummary].self, from: data) {
            return direct
        }
        throw AuthFlowError.invalidResponse
    }
}
