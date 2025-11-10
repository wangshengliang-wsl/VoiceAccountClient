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
    
    var body: some View {
        NavigationView {
            ZStack {
                // 使用主题背景
                ThemedBackgroundView()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // 顶部状态区域
                    VStack(spacing: 16) {
                        if audioRecorder.isRecording {
                            // 录音时间
                            Text(audioRecorder.formattedTime())
                                .font(.system(size: 56, weight: .light, design: .rounded))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else if isUploading {
                            // 上传中
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text(uploadStatus)
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else if showSuccess {
                            // 成功状态
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.green)
                                
                                Text("上传成功")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            // 准备状态
                            Text("轻触开始录音")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                                .transition(.opacity)
                        }
                    }
                    .frame(height: 120)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: audioRecorder.isRecording)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isUploading)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSuccess)
                    
                    Spacer()
                    
                    // 声波效果区域
                    ZStack {
                        if audioRecorder.isRecording {
                            SoundWaveView(isAnimating: .constant(audioRecorder.isRecording))
                                .frame(height: 100)
                                .padding(.horizontal, 40)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .frame(height: 120)
                    .animation(.easeInOut(duration: 0.3), value: audioRecorder.isRecording)
                    
                    Spacer()
                    
                    // 中央录音按钮
                    ZStack {
                        // 脉冲圆环效果
                        if audioRecorder.isRecording {
                            ForEach(0..<3) { index in
                                PulseRingView(delay: Double(index) * 0.6)
                                    .frame(width: 120, height: 120)
                            }
                            .transition(.opacity)
                        }
                        
                        // 主按钮
                        Button(action: {
                            if audioRecorder.isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            ZStack {
                                // 外圈
                                Circle()
                                    .strokeBorder(
                                        (colorScheme == .dark ? Color.white : Color.primary).opacity(0.2),
                                        lineWidth: 2
                                    )
                                    .frame(width: 140, height: 140)
                                
                                // 主圆形
                                Circle()
                                    .fill(
                                        audioRecorder.isRecording
                                        ? LinearGradient(
                                            colors: [Color.red, Color.red.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        : LinearGradient(
                                            colors: [
                                                colorScheme == .dark ? Color.white : Color(red: 0.95, green: 0.95, blue: 0.97),
                                                colorScheme == .dark ? Color.white.opacity(0.9) : Color(red: 0.9, green: 0.9, blue: 0.92)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(
                                        color: audioRecorder.isRecording
                                        ? Color.red.opacity(0.5)
                                        : (colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2)),
                                        radius: 20,
                                        x: 0,
                                        y: 10
                                    )
                                    .scaleEffect(micScale)
                                
                                // 图标
                                Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 52, weight: .medium))
                                    .foregroundColor(
                                        audioRecorder.isRecording
                                        ? .white
                                        : (colorScheme == .dark ? Color(red: 0.05, green: 0.05, blue: 0.15) : Color(red: 0.2, green: 0.2, blue: 0.3))
                                    )
                                    .scaleEffect(audioRecorder.isRecording ? 0.7 : 1.0)
                            }
                        }
                        .disabled(isUploading)
                    }
                    .frame(height: 200)
                    .onChange(of: audioRecorder.isRecording) { _, isRecording in
                        if isRecording {
                            startMicAnimation()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                micScale = 1.0
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 底部提示
                    VStack(spacing: 8) {
                        if !audioRecorder.isRecording && !isUploading {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                Text("录音将自动上传到云端")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(height: 40)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("语音记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if audioRecorder.isRecording {
                            audioRecorder.cancelRecording()
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .primary.opacity(0.7))
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
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
                    uploadStatus = ""
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                    
                    // 延迟关闭
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else {
                    uploadStatus = ""
                    alertMessage = response.message
                    showingAlert = true
                }
                
            case .failure(let error):
                uploadStatus = ""
                alertMessage = "上传失败: \(error.localizedDescription)"
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

