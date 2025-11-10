//
//  PrivacyPolicyView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.96, blue: 0.9),
                        Color(red: 1.0, green: 0.88, blue: 0.7),
                        Color(red: 1.0, green: 0.8, blue: 0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 标题
                        VStack(alignment: .leading, spacing: 8) {
                            Text("隐私政策")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("最后更新日期：2025年11月")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                        
                        // 前言
                        PolicySectionView(
                            title: "前言",
                            content: """
                            欢迎使用语音记账应用。我们非常重视您的隐私权益。本隐私政策说明了我们如何收集、使用、存储和保护您的个人信息。
                            
                            使用本应用即表示您同意本隐私政策中描述的做法。如果您不同意本隐私政策，请不要使用本应用。
                            """
                        )
                        
                        // 信息收集
                        PolicySectionView(
                            title: "1. 信息收集",
                            content: """
                            1.1 本地存储信息
                            • 记账数据：包括金额、分类、日期、备注等信息
                            • 语音数据：用于语音识别的临时音频数据
                            • 设置偏好：货币单位、分类设置等个性化配置
                            
                            1.2 本应用采用完全本地化存储
                            • 所有数据仅存储在您的设备上
                            • 我们不会将您的数据上传到任何服务器
                            • 您的隐私数据始终在您的掌控之中
                            """
                        )
                        
                        // 信息使用
                        PolicySectionView(
                            title: "2. 信息使用",
                            content: """
                            2.1 功能实现
                            • 记账数据用于生成统计图表和分析报告
                            • 语音数据仅用于识别并转换为文字记录
                            • 设置数据用于个性化您的使用体验
                            
                            2.2 数据处理
                            • 语音识别在设备本地完成（使用系统 API）
                            • 所有数据计算和分析均在本地进行
                            • 不涉及任何第三方数据传输
                            """
                        )
                        
                        // 数据安全
                        PolicySectionView(
                            title: "3. 数据安全",
                            content: """
                            3.1 本地加密
                            • 您的数据受 iOS 系统级别的安全保护
                            • 应用数据存储在沙盒环境中
                            • 使用系统提供的安全机制保护您的隐私
                            
                            3.2 数据控制
                            • 您可以随时导出数据备份
                            • 您可以随时清除所有本地数据
                            • 卸载应用将完全删除所有数据
                            """
                        )
                        
                        // 权限说明
                        PolicySectionView(
                            title: "4. 权限说明",
                            content: """
                            本应用可能请求以下权限：
                            
                            • 麦克风权限：用于语音记账功能
                            • 语音识别权限：用于将语音转换为文字
                            
                            所有权限请求均会明确说明用途，您可以在系统设置中随时管理这些权限。
                            """
                        )
                        
                        // 儿童隐私
                        PolicySectionView(
                            title: "5. 儿童隐私保护",
                            content: """
                            本应用不会故意收集 13 岁以下儿童的个人信息。如果您是家长或监护人，发现您的孩子向我们提供了个人信息，请联系我们。
                            """
                        )
                        
                        // 政策更新
                        PolicySectionView(
                            title: "6. 隐私政策更新",
                            content: """
                            我们可能会不定期更新本隐私政策。更新后的政策将在应用中发布，并更新"最后更新日期"。建议您定期查看本政策以了解最新信息。
                            """
                        )
                        
                        // 联系我们
                        PolicySectionView(
                            title: "7. 联系我们",
                            content: """
                            如果您对本隐私政策有任何疑问或建议，欢迎通过以下方式联系我们：
                            
                            • 应用内反馈
                            • 邮箱：privacy@voiceaccount.app
                            
                            我们将在收到您的反馈后尽快回复。
                            """
                        )
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PolicySectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

#Preview {
    PrivacyPolicyView()
}

