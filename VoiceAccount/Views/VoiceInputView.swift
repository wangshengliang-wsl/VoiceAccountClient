import SwiftUI

struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var audioRecorder: AudioRecorder
    @ObservedObject private var categoryManager = CategoryManager.shared
    @Binding var isUploading: Bool
    @Binding var uploadStatus: String

    @State private var hasPermission = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var micScale: CGFloat = 1.0
    @State private var showSuccess = false
    @State private var recognitionResult = ""

    // AI解析相关状态
    @State private var isParsingAudio = false
    @State private var parsedItems: [AccountingItem] = []
    @State private var showEditView = false
    @State private var animationRotation = 0.0
    @State private var pulseOpacity = 0.5
    
    var body: some View {
        NavigationView {
            ZStack {
                // 使用主题背景
                ThemedBackgroundView()

                VStack(spacing: 0) {
                    Spacer()

                    // 中央录音按钮或AI解析动画
                    if isParsingAudio {
                        // AI解析动画
                        ZStack {
                            // 外圈脉动动画
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.6),
                                            Color.purple.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 160, height: 160)
                                .opacity(pulseOpacity)
                                .scaleEffect(micScale)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                    value: pulseOpacity
                                )

                            // 中心圆形
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.5, green: 0.3, blue: 0.9),
                                            Color(red: 0.3, green: 0.2, blue: 0.8)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(
                                    color: Color.purple.opacity(0.4),
                                    radius: 20,
                                    x: 0,
                                    y: 10
                                )

                            // AI图标动画
                            Image(systemName: "brain.filled.head.profile")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.white)
                                .rotationEffect(Angle(degrees: animationRotation))
                                .animation(
                                    .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true),
                                    value: animationRotation
                                )
                        }
                        .onAppear {
                            withAnimation {
                                animationRotation = 10
                                pulseOpacity = 1.0
                                micScale = 1.1
                            }
                        }
                    } else {
                        // 录音按钮
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
                        .disabled(isUploading || isParsingAudio)
                    }
                    
                    // 点击开始录音提示
                    Text(audioRecorder.isRecording ? "录音中..." : "点击开始录音")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    Spacer()

                    // 识别结果区域 - 显示AI解析状态或结果
                    if isParsingAudio {
                        VStack(spacing: 8) {
                            Text("AI 解析中...")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("正在识别语音并提取记账信息")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    } else if !parsedItems.isEmpty {
                        // 显示解析结果预览
                        VStack(alignment: .leading, spacing: 8) {
                            Text("识别到 \(parsedItems.count) 条记账信息")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.7))

                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(parsedItems.indices, id: \.self) { index in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text("\(parsedItems[index].title)")
                                                    .font(.system(size: 13))
                                                Spacer()
                                                Text("¥\(String(format: "%.2f", parsedItems[index].amount))")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.blue)
                                            }
                                            if let date = parsedItems[index].date {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "calendar")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.secondary)
                                                    Text(formatDate(date))
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(12)
                            }
                            .frame(maxHeight: 120)
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

                    // 底部保存/编辑按钮
                    Group {
                        if !parsedItems.isEmpty {
                            Button(action: {
                                // 打开编辑界面
                                showEditView = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 20))
                                    Text("编辑并保存")
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
                        } else {
                            Button(action: {
                                // 返回或保存
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("完成")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.3),
                                            Color.gray.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.primary)
                                .cornerRadius(16)
                            }
                            .disabled(isParsingAudio || isUploading)
                        }
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
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showEditView) {
                AccountingEditView(items: $parsedItems)
                    .environmentObject(themeManager)
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
        recognitionResult = ""  // 清空之前的结果

        NetworkManager.shared.uploadAudio(fileURL: fileURL) { result in
            isUploading = false

            switch result {
            case .success(let response):
                if response.status == "success" {
                    uploadStatus = ""

                    // 获取上传成功的音频URL
                    guard let audioURL = response.data?.url else {
                        alertMessage = "获取音频URL失败"
                        showingAlert = true
                        return
                    }

                    // 开始AI解析
                    parseAudioWithAI(audioURL: audioURL)

                } else {
                    uploadStatus = ""
                    alertMessage = response.message
                    showingAlert = true
                }

            case .failure(let error):
                uploadStatus = ""
                let errorMsg = error.localizedDescription
                if errorMsg.contains("上传失败") || errorMsg.contains("失败") {
                    alertMessage = errorMsg
                } else {
                    alertMessage = "上传失败: \(errorMsg)"
                }
                showingAlert = true
            }
        }
    }

    private func parseAudioWithAI(audioURL: String) {
        // 开始显示AI解析动画
        isParsingAudio = true
        parsedItems = []

        // 使用 CategoryManager 的分类列表
        let categories = categoryManager.allCategories.map { $0.name }

        // 调用AI解析接口
        NetworkManager.shared.parseVoice(audioURL: audioURL, categories: categories) { result in
            isParsingAudio = false

            switch result {
            case .success(let response):
                if response.status == "success" || response.status == "partial_success" {
                    if let items = response.data, !items.isEmpty {
                        parsedItems = items
                        // 成功解析，显示结果
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showSuccess = true
                        }
                    } else {
                        alertMessage = "未能识别到记账信息，请重试"
                        showingAlert = true
                    }
                } else {
                    alertMessage = response.message
                    showingAlert = true
                }

            case .failure(let error):
                alertMessage = "AI解析失败: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
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

