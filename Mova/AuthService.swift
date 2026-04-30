import Foundation

struct AuthService {
    func normalizeBaseURL(from address: String) -> URL? {
        var normalized = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.lowercased().hasPrefix("http://") && !normalized.lowercased().hasPrefix("https://") {
            normalized = "http://\(normalized)"
        }

        guard var components = URLComponents(string: normalized),
              let scheme = components.scheme,
              let host = components.host,
              !scheme.isEmpty,
              !host.isEmpty else {
            return nil
        }

        if components.path == "/" {
            components.path = ""
        }

        return components.url
    }

    func apiURL(baseURL: URL, apiPath: String) -> URL {
        let trimmedPath = apiPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if let absolute = URL(string: trimmedPath), absolute.scheme != nil {
            return absolute
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
        var basePath = components.path
        var endpointPath = trimmedPath
        var endpointQuery: String?

        if let endpointComponents = URLComponents(string: trimmedPath) {
            endpointPath = endpointComponents.path.isEmpty ? trimmedPath : endpointComponents.path
            endpointQuery = endpointComponents.percentEncodedQuery
        }

        if basePath == "/" {
            basePath = ""
        }

        if basePath.hasSuffix("/api"), endpointPath.hasPrefix("/api/") {
            endpointPath = String(endpointPath.dropFirst(4))
        }

        components.path = "\(basePath)\(endpointPath)"
            .replacingOccurrences(of: "//", with: "/")

        if !components.path.hasPrefix("/") {
            components.path = "/" + components.path
        }

        if let endpointQuery, !endpointQuery.isEmpty {
            components.percentEncodedQuery = endpointQuery
        }

        return components.url ?? baseURL.appendingPathComponent(apiPath)
    }

    func checkHealth(baseURL: URL) async throws {
        var request = URLRequest(url: apiURL(baseURL: baseURL, apiPath: "/api/health"))
        request.httpMethod = "GET"
        request.timeoutInterval = 8

        let (_, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.serverUnreachable(statusCode: httpResponse.statusCode)
        }
    }

    func tokenLogin(baseURL: URL, username: String, password: String) async throws -> TokenLoginResponse {
        var request = URLRequest(url: apiURL(baseURL: baseURL, apiPath: "/api/auth/token-login"))
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(TokenLoginRequest(username: username, password: password))

        let (data, response) = try await NetworkClient.sharedSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw AuthFlowError.invalidCredentials
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.tokenLoginFailed(statusCode: httpResponse.statusCode)
        }

        if let envelope = try? JSONDecoder().decode(APIEnvelope<TokenLoginResponse>.self, from: data),
           let payload = envelope.data {
            return payload
        }

        if let direct = try? JSONDecoder().decode(TokenLoginResponse.self, from: data) {
            return direct
        }

        throw AuthFlowError.invalidTokenPayload
    }

    func checkCurrentSession(baseURL: URL, token: String) async throws {
        var request = URLRequest(url: apiURL(baseURL: baseURL, apiPath: "/api/auth/me"))
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthFlowError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthFlowError.sessionExpired
        }
    }
}
