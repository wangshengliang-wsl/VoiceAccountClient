import Foundation

/// 服务器配置管理器
/// 从 Config.plist 或 Info.plist 读取配置,如果没有则使用默认值
class ServerConfig {
    static let shared = ServerConfig()

    /// 服务器主机地址(从配置文件读取,默认 localhost)
    let host: String

    /// 服务器端口(从配置文件读取,默认 5001)
    let port: Int

    /// 完整的服务器基础 URL
    var baseURL: String {
        return "http://\(host):\(port)"
    }

    private init() {
        let bundle = Bundle.main
        var configHost: String? = nil
        var configPort: Int? = nil

        // 首先尝试从 Config.plist 读取
        if let configPath = bundle.path(forResource: "Config", ofType: "plist"),
           let configDict = NSDictionary(contentsOfFile: configPath) {
            configHost = configDict["ServerHost"] as? String
            if let portString = configDict["ServerPort"] as? String {
                configPort = Int(portString)
            } else if let portInt = configDict["ServerPort"] as? Int {
                configPort = portInt
            }
        }

        // 如果 Config.plist 中没有,尝试从 Info.plist 读取
        if configHost == nil {
            configHost = bundle.object(forInfoDictionaryKey: "ServerHost") as? String
        }
        if configPort == nil {
            if let portString = bundle.object(forInfoDictionaryKey: "ServerPort") as? String {
                configPort = Int(portString)
            } else if let portInt = bundle.object(forInfoDictionaryKey: "ServerPort") as? Int {
                configPort = portInt
            }
        }

        // 设置值,如果没有则使用默认值
        self.host = configHost ?? "localhost"
        self.port = configPort ?? 5001
    }
}
