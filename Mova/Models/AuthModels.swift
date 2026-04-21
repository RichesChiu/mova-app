import Foundation

enum SourceType {
    case server

    var title: String {
        switch self {
        case .server:
            return "服务器"
        }
    }
}

struct APIEnvelope<T: Decodable>: Decodable {
    let code: Int?
    let message: String?
    let data: T?
}

struct TokenLoginRequest: Encodable {
    let username: String
    let password: String
}

struct TokenLoginResponse: Decodable {
    let token: String
    let tokenType: String?
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case token
        case tokenType = "token_type"
        case expiresAt = "expires_at"
    }
}

enum AuthFlowError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverUnreachable(statusCode: Int)
    case invalidCredentials
    case tokenLoginFailed(statusCode: Int)
    case invalidTokenPayload
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "服务器地址无效。"
        case .invalidResponse:
            return "服务器返回了无效响应。"
        case let .serverUnreachable(statusCode):
            return "服务器不可用（HTTP \(statusCode)）。"
        case .invalidCredentials:
            return "账号或密码错误。"
        case let .tokenLoginFailed(statusCode):
            return "Token 登录失败（HTTP \(statusCode)）。"
        case .invalidTokenPayload:
            return "登录成功但 token 响应格式无法识别。"
        case .sessionExpired:
            return "当前登录态已失效。"
        }
    }
}
