import Foundation
import AVFoundation
import Combine

/// 录音管理器
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioFileURL: URL?
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var startTime: Date?
    
    /// 请求录音权限
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// 开始录音
    func startRecording() {
        // 检查权限
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            errorMessage = "需要麦克风权限才能录音"
            return
        }
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            errorMessage = "无法配置音频会话: \(error.localizedDescription)"
            return
        }
        
        // 创建录音文件路径
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let audioFilename = documentsPath.appendingPathComponent(fileName)
        
        // 配置录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            audioFileURL = audioFilename
            startTime = Date()
            recordingTime = 0
            
            // 启动计时器
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let startTime = self.startTime else { return }
                self.recordingTime = Date().timeIntervalSince(startTime)
            }
            
            print("开始录音: \(audioFilename.path)")
        } catch {
            errorMessage = "无法开始录音: \(error.localizedDescription)"
        }
    }
    
    /// 停止录音
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // 停用音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("停用音频会话失败: \(error.localizedDescription)")
        }
        
        print("停止录音，文件保存在: \(audioFileURL?.path ?? "未知")")
    }
    
    /// 取消录音并删除文件
    func cancelRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // 删除录音文件
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        audioFileURL = nil
        recordingTime = 0
        
        // 停用音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("停用音频会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 格式化时间显示
    func formattedTime() -> String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        let milliseconds = Int((recordingTime.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "录音失败"
            audioFileURL = nil
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        errorMessage = "录音编码错误: \(error?.localizedDescription ?? "未知错误")"
        isRecording = false
    }
}

