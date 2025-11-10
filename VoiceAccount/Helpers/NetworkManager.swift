import Foundation
import Combine

/// 网络管理器
class NetworkManager {
    static let shared = NetworkManager()

    // 服务器地址(从 ServerConfig 动态获取)
    private let baseURL: String

    private init() {
        self.baseURL = ServerConfig.shared.baseURL
    }

    /// 上传音频文件到服务器
    /// - Parameters:
    ///   - fileURL: 音频文件 URL
    ///   - userID: 用户 ID(可选)
    ///   - completion: 完成回调
    func uploadAudio(fileURL: URL, userID: String = "anonymous", completion: @escaping (Result<UploadResponse, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/upload-audio"

        guard let url = URL(string: endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // 创建 multipart/form-data 请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // 读取文件数据
        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(.failure(NetworkError.fileReadError))
            return
        }

        // 构建 multipart 数据
        var body = Data()

        // 添加 user_id 字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userID)\r\n".data(using: .utf8)!)

        // 添加文件字段
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 处理网络错误
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.uploadFailed("网络错误: \(error.localizedDescription)")))
                }
                return
            }

            // 检查 HTTP 响应
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.uploadFailed("无效的服务器响应")))
                }
                return
            }

            // 检查数据是否存在
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }

            // 检查状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                // 尝试解析错误响应
                var errorMessage = "服务器错误"

                let decoder = JSONDecoder()
                // 注意：由于我们显式实现了 Codable，keyDecodingStrategy 不会自动应用
                if let errorResponse = try? decoder.decode(UploadResponse.self, from: data) {
                    errorMessage = errorResponse.message
                } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let message = json["message"] as? String {
                    errorMessage = message
                }

                // 针对 403 错误提供更友好的提示
                if httpResponse.statusCode == 403 {
                    errorMessage = "权限不足 (403)\n\n请检查 Supabase Storage 配置:\n1. 确认 'user-audio' bucket 已创建\n2. 将 bucket 设置为公开 (Public)\n3. 检查 Service Role Key 是否正确\n4. 配置 Storage Policies 允许上传"
                }

                DispatchQueue.main.async {
                    completion(.failure(NetworkError.uploadFailed(errorMessage)))
                }
                return
            }

            // 解析响应
            do {
                let decoder = JSONDecoder()
                // 注意：由于我们显式实现了 Codable，keyDecodingStrategy 不会自动应用
                // 我们已经在 CodingKeys 中手动映射了字段
                let uploadResponse = try decoder.decode(UploadResponse.self, from: data)

                DispatchQueue.main.async {
                    completion(.success(uploadResponse))
                }
            } catch let decodingError {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.uploadFailed("响应格式错误: \(decodingError.localizedDescription)")))
                }
            }
        }

        task.resume()
    }

    /// 解析语音内容，提取记账明细
    /// - Parameters:
    ///   - audioURL: 音频文件的URL地址
    ///   - categories: 用户自定义的分类列表
    ///   - completion: 完成回调
    func parseVoice(audioURL: String, categories: [String] = [], completion: @escaping (Result<ParseVoiceResponse, Error>) -> Void) {
        let endpoint = "\(baseURL)/api/parse-voice"

        guard let url = URL(string: endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 构建请求体
        let body: [String: Any] = [
            "audio_url": audioURL,
            "categories": categories
        ]

        // 编码为JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(NetworkError.uploadFailed("无法编码请求数据")))
            return
        }

        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 处理网络错误
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.uploadFailed("网络错误: \(error.localizedDescription)")))
                }
                return
            }

            // 检查HTTP响应
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.uploadFailed("无效的服务器响应")))
                }
                return
            }

            // 检查数据
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }

            // 检查状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                // 尝试解析错误响应
                var errorMessage = "服务器错误"

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    errorMessage = message
                }

                DispatchQueue.main.async {
                    completion(.failure(NetworkError.uploadFailed(errorMessage)))
                }
                return
            }

            // 解析响应
            do {
                let decoder = JSONDecoder()
                // 注意：由于我们显式实现了 Codable，keyDecodingStrategy 不会自动应用
                // 我们已经在 CodingKeys 中手动映射了字段
                let response = try decoder.decode(ParseVoiceResponse.self, from: data)

                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch let decodingError {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.uploadFailed("响应解析错误: \(decodingError.localizedDescription)")))
                }
            }
        }

        task.resume()
    }
}

// MARK: - 数据模型
struct UploadResponse: @unchecked Sendable {
    let status: String
    let message: String
    let data: UploadData?
}

extension UploadResponse: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        message = try container.decode(String.self, forKey: .message)
        data = try container.decodeIfPresent(UploadData.self, forKey: .data)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
    }
    
    enum CodingKeys: String, CodingKey {
        case status, message, data
    }
}

struct UploadData: @unchecked Sendable {
    let url: String
    let filename: String
    let path: String
    let size: Int
    let contentType: String
}

extension UploadData: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        filename = try container.decode(String.self, forKey: .filename)
        path = try container.decode(String.self, forKey: .path)
        size = try container.decode(Int.self, forKey: .size)
        // 服务器返回的是 content_type，需要手动映射
        contentType = try container.decode(String.self, forKey: .contentType)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(filename, forKey: .filename)
        try container.encode(path, forKey: .path)
        try container.encode(size, forKey: .size)
        try container.encode(contentType, forKey: .contentType)
    }
    
    enum CodingKeys: String, CodingKey {
        case url, filename, path, size
        case contentType = "content_type"
    }
}

// MARK: - 语音解析响应模型
struct ParseVoiceResponse: @unchecked Sendable {
    let status: String
    let message: String
    let data: [AccountingItem]?
    let rawResponse: String?
}

extension ParseVoiceResponse: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        message = try container.decode(String.self, forKey: .message)
        data = try container.decodeIfPresent([AccountingItem].self, forKey: .data)
        rawResponse = try container.decodeIfPresent(String.self, forKey: .rawResponse)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(rawResponse, forKey: .rawResponse)
    }
    
    enum CodingKeys: String, CodingKey {
        case status, message, data
        case rawResponse = "raw_response"
    }
}

struct AccountingItem: @unchecked Sendable {
    let amount: Double
    let title: String
    let category: String
    let date: Date?
    
    init(amount: Double, title: String, category: String, date: Date? = nil) {
        self.amount = amount
        self.title = title
        self.category = category
        self.date = date
    }
}

extension AccountingItem: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = try container.decode(Double.self, forKey: .amount)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(String.self, forKey: .category)
        
        // 解析日期（可选字段）
        if let dateString = try? container.decode(String.self, forKey: .date) {
            // 尝试多种日期格式
            var parsedDate: Date?
            
            // 尝试 ISO8601 格式（带小数秒）
            let iso8601WithFractional = ISO8601DateFormatter()
            iso8601WithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601WithFractional.date(from: dateString) {
                parsedDate = date
            }
            
            // 尝试 ISO8601 格式（不带小数秒）
            if parsedDate == nil {
                let iso8601 = ISO8601DateFormatter()
                iso8601.formatOptions = [.withInternetDateTime]
                if let date = iso8601.date(from: dateString) {
                    parsedDate = date
                }
            }
            
            // 尝试标准日期时间格式
            if parsedDate == nil {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = formatter.date(from: dateString) {
                    parsedDate = date
                }
            }
            
            // 尝试空格分隔的日期时间格式
            if parsedDate == nil {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = formatter.date(from: dateString) {
                    parsedDate = date
                }
            }
            
            date = parsedDate ?? Date()
        } else {
            date = nil
        }
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(amount, forKey: .amount)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        if let date = date {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: date), forKey: .date)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case amount, title, category, date
    }
}

// MARK: - 错误类型
enum NetworkError: LocalizedError {
    case invalidURL
    case fileReadError
    case noData
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .fileReadError:
            return "无法读取文件"
        case .noData:
            return "服务器没有返回数据"
        case .uploadFailed(let message):
            return "上传失败: \(message)"
        }
    }
}
