import SwiftUI

struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var audioRecorder: AudioRecorder
    @Binding var isUploading: Bool
    @Binding var uploadStatus: String
    
    @State private var hasPermission = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.3),
                        Color(red: 0.46, green: 0.29, blue: 0.64).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // 录音时间显示
                    if audioRecorder.isRecording {
                        Text(audioRecorder.formattedTime())
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    } else {
                        Text("准备录音")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    // 录音按钮
                    Button(action: {
                        if audioRecorder.isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(audioRecorder.isRecording ? Color.red : Color.white)
                                .frame(width: 120, height: 120)
                                .shadow(color: .black.opacity(0.3), radius: 10)
                                .scaleEffect(scale)
                            
                            Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(audioRecorder.isRecording ? .white : Color(red: 0.4, green: 0.49, blue: 0.92))
                        }
                    }
                    .onChange(of: audioRecorder.isRecording) { _, isRecording in
                        if isRecording {
                            startPulseAnimation()
                        } else {
                            scale = 1.0
                        }
                    }
                    
                    // 状态信息
                    if !uploadStatus.isEmpty {
                        Text(uploadStatus)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                    
                    if isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    
                    Spacer()
                    
                    // 提示文本
                    Text(audioRecorder.isRecording ? "点击停止录音" : "点击麦克风开始录音")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 40)
                }
                .padding()
            }
            .navigationTitle("语音输入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if audioRecorder.isRecording {
                            audioRecorder.cancelRecording()
                        }
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                checkPermission()
            }
        }
    }
    
    private func checkPermission() {
        audioRecorder.requestPermission { granted in
            hasPermission = granted
            if !granted {
                alertMessage = "需要麦克风权限才能录音，请在设置中允许访问麦克风"
                showingAlert = true
            }
        }
    }
    
    private func startRecording() {
        guard hasPermission else {
            alertMessage = "没有麦克风权限"
            showingAlert = true
            return
        }
        
        uploadStatus = ""
        audioRecorder.startRecording()
    }
    
    private func stopRecording() {
        audioRecorder.stopRecording()
        
        // 停止录音后上传文件
        guard let fileURL = audioRecorder.audioFileURL else {
            alertMessage = "录音文件不存在"
            showingAlert = true
            return
        }
        
        uploadAudioFile(fileURL)
    }
    
    private func uploadAudioFile(_ fileURL: URL) {
        isUploading = true
        uploadStatus = "正在上传..."
        
        NetworkManager.shared.uploadAudio(fileURL: fileURL) { result in
            isUploading = false
            
            switch result {
            case .success(let response):
                if response.status == "success" {
                    uploadStatus = "上传成功！"
                    alertMessage = "录音已上传成功\n文件: \(response.data?.filename ?? "")"
                    showingAlert = true
                    
                    // 延迟关闭
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                } else {
                    uploadStatus = "上传失败"
                    alertMessage = response.message
                    showingAlert = true
                }
                
            case .failure(let error):
                uploadStatus = "上传失败"
                alertMessage = "上传失败: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            scale = 1.1
        }
    }
}

#Preview {
    VoiceInputView(
        audioRecorder: AudioRecorder(),
        isUploading: .constant(false),
        uploadStatus: .constant("")
    )
}

