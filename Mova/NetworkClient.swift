import Foundation

struct NetworkClient {
    static let sharedSession: URLSession = {
        let configuration = URLSessionConfiguration.default

        #if DEBUG
        if let proxy = debugProxySettings() {
            configuration.connectionProxyDictionary = proxy
        }
        #endif

        return URLSession(configuration: configuration)
    }()

    #if DEBUG
    private static func debugProxySettings() -> [AnyHashable: Any]? {
        let env = ProcessInfo.processInfo.environment

        guard let host = env["PROXY_HOST"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !host.isEmpty else {
            return nil
        }

        let portString = env["PROXY_PORT"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "9091"
        guard let port = Int(portString), (1...65535).contains(port) else {
            return nil
        }

        return [
            kCFNetworkProxiesHTTPEnable as String: true,
            kCFNetworkProxiesHTTPProxy as String: host,
            kCFNetworkProxiesHTTPPort as String: port,
            "HTTPSEnable": true,
            "HTTPSProxy": host,
            "HTTPSPort": port
        ]
    }
    #endif
}
