import Foundation
import Combine

/// 网络管理器
class NetworkManager {
    static let shared = NetworkManager()
    
    // 服务器地址（需要根据实际情况修改）
    private let baseURL = "http://localhost:5000"
    
    private init() {}
    
    /// 上传音频文件到服务器
    /// - Parameters:
    ///   - fileURL: 音频文件 URL
    ///   - userID: 用户 ID（可选）
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
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }
            
            // 解析响应
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(UploadResponse.self, from: data)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - 数据模型
struct UploadResponse: Codable {
    let status: String
    let message: String
    let data: UploadData?
}

struct UploadData: Codable {
    let url: String
    let filename: String
    let path: String
    let size: Int
    let contentType: String
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

