import SwiftUI

struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var audioRecorder: AudioRecorder
    @Binding var isUploading: Bool
    @Binding var uploadStatus: String

    @State private var hasPermission = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var micScale: CGFloat = 1.0
    @State private var showSuccess = false
    @State private var recognitionResult = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 使用主题背景
                ThemedBackgroundView()

                VStack(spacing: 0) {
                    // 点击开始录音提示
                    Text(audioRecorder.isRecording ? "录音中..." : "点击开始录音")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                        .padding(.top, 40)
                        .padding(.bottom, 60)

                    Spacer()

                    // 中央录音按钮
                    Button(action: {
                        if audioRecorder.isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        ZStack {
                            // 主圆形 - 蓝色渐变
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.6, blue: 1.0),
                                            Color(red: 0.2, green: 0.4, blue: 0.9)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .shadow(
                                    color: Color.blue.opacity(0.3),
                                    radius: 20,
                                    x: 0,
                                    y: 10
                                )
                                .scaleEffect(micScale)

                            // 麦克风图标
                            Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 56, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isUploading)

                    Spacer()

                    // 识别结果区域
                    if !recognitionResult.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("识别结果")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.7))

                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(recognitionResult)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                                    .padding(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    } else {
                        Spacer()
                            .frame(height: 80)
                    }

                    // 底部保存按钮
                    Button(action: {
                        // 保存操作
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("保存")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.49, blue: 0.92),
                                    Color(red: 0.46, green: 0.29, blue: 0.64)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.3), radius: 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("语音记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if audioRecorder.isRecording {
                            audioRecorder.cancelRecording()
                        }
                        dismiss()
                    } label: {
                        Text("关闭")
                            .font(.system(size: 16))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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

        // 显示文件路径
        recognitionResult = fileURL.path

        NetworkManager.shared.uploadAudio(fileURL: fileURL) { result in
            isUploading = false

            switch result {
            case .success(let response):
                if response.status == "success" {
                    uploadStatus = ""
                    recognitionResult = "上传成功: \(response.data?.url ?? "")"

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                } else {
                    uploadStatus = ""
                    alertMessage = response.message
                    showingAlert = true
                }

            case .failure(let error):
                uploadStatus = ""
                // 如果错误信息已经包含"上传失败"或"失败",则不再添加前缀
                let errorMsg = error.localizedDescription
                if errorMsg.contains("上传失败") || errorMsg.contains("失败") {
                    alertMessage = errorMsg
                } else {
                    alertMessage = "上传失败: \(errorMsg)"
                }
                recognitionResult = "上传失败"
                showingAlert = true
            }
        }
    }

    private func startMicAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            micScale = 1.05
        }
    }
}

#Preview {
    VoiceInputView(
        audioRecorder: AudioRecorder(),
        isUploading: .constant(false),
        uploadStatus: .constant("")
    )
    .environmentObject(ThemeManager.shared)
}

