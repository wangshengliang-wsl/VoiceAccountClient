//
//  UserAgreementView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI

struct UserAgreementView: View {
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
                            Text("用户协议")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("最后更新日期：2025年11月")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                        
                        // 协议接受
                        AgreementSectionView(
                            title: "协议接受",
                            content: """
                            欢迎使用语音记账应用（以下简称"本应用"）。在使用本应用之前，请您仔细阅读并充分理解本协议的全部内容。
                            
                            您下载、安装、使用本应用的行为即视为您已阅读并同意受本协议的约束。如果您不同意本协议的任何条款，请不要使用本应用。
                            """
                        )
                        
                        // 服务说明
                        AgreementSectionView(
                            title: "1. 服务说明",
                            content: """
                            1.1 服务内容
                            本应用是一款个人财务管理工具，提供以下功能：
                            • 语音记账和手动记账
                            • 支出统计与数据分析
                            • 分类管理和个性化设置
                            • 数据导出和备份
                            
                            1.2 服务特点
                            • 完全本地化运行，无需网络连接
                            • 数据存储在您的设备本地
                            • 不涉及账号注册和云端同步
                            """
                        )
                        
                        // 使用规则
                        AgreementSectionView(
                            title: "2. 使用规则",
                            content: """
                            2.1 合法使用
                            • 您应当合法、正当地使用本应用
                            • 不得利用本应用从事违法活动
                            • 不得干扰或损害本应用的正常运行
                            
                            2.2 个人使用
                            • 本应用仅供个人非商业用途使用
                            • 未经许可不得用于商业目的
                            • 不得对应用进行反向工程或破解
                            """
                        )
                        
                        // 用户责任
                        AgreementSectionView(
                            title: "3. 用户责任",
                            content: """
                            3.1 数据管理
                            • 您对自己创建和存储的数据负完全责任
                            • 建议定期备份重要数据
                            • 删除数据前请谨慎操作
                            
                            3.2 设备安全
                            • 保护好您的设备访问权限
                            • 防止他人未经授权访问您的数据
                            • 遗失设备时及时采取安全措施
                            
                            3.3 语音功能
                            • 在使用语音功能时遵守公共场所规范
                            • 确保语音识别内容的准确性
                            • 对识别结果进行必要的核对
                            """
                        )
                        
                        // 知识产权
                        AgreementSectionView(
                            title: "4. 知识产权",
                            content: """
                            4.1 应用权利
                            本应用的一切知识产权，以及与本应用相关的所有信息内容，包括但不限于：
                            • 软件代码、界面设计、图标
                            • 文字、图片、音频等内容
                            • 商标、标识等
                            均归本应用开发者所有。
                            
                            4.2 用户数据
                            您对自己创建的记账数据享有完全的所有权和控制权。
                            """
                        )
                        
                        // 免责声明
                        AgreementSectionView(
                            title: "5. 免责声明",
                            content: """
                            5.1 服务中断
                            • 因设备故障、系统更新等原因导致的服务中断
                            • 因不可抗力因素造成的服务问题
                            
                            5.2 数据准确性
                            • 语音识别结果可能存在误差，请核对确认
                            • 统计分析仅供参考，不构成财务建议
                            • 因数据录入错误导致的损失由用户自行承担
                            
                            5.3 系统兼容
                            • 本应用可能无法在所有设备上完美运行
                            • 系统升级可能影响应用功能
                            • 我们会尽力保证兼容性但不做绝对保证
                            """
                        )
                        
                        // 服务变更
                        AgreementSectionView(
                            title: "6. 服务变更与终止",
                            content: """
                            6.1 功能更新
                            • 我们可能随时更新或修改应用功能
                            • 重大变更将通过适当方式通知用户
                            • 更新可能需要您的确认和同意
                            
                            6.2 服务终止
                            • 您可以随时停止使用并卸载应用
                            • 卸载应用将删除所有本地数据
                            • 请在卸载前做好数据备份
                            """
                        )
                        
                        // 协议修改
                        AgreementSectionView(
                            title: "7. 协议修改",
                            content: """
                            我们保留随时修改本协议的权利。修改后的协议将在应用中发布，并更新"最后更新日期"。
                            
                            继续使用本应用即表示您接受修改后的协议。如果您不同意修改内容，请停止使用本应用。
                            """
                        )
                        
                        // 法律适用
                        AgreementSectionView(
                            title: "8. 法律适用",
                            content: """
                            本协议的签订、履行、解释及争议解决均适用中华人民共和国法律。
                            
                            如双方就本协议内容或其执行发生任何争议，双方应友好协商解决；协商不成时，任何一方均可向有管辖权的人民法院提起诉讼。
                            """
                        )
                        
                        // 联系方式
                        AgreementSectionView(
                            title: "9. 联系我们",
                            content: """
                            如果您对本协议有任何疑问或建议，欢迎通过以下方式联系我们：
                            
                            • 应用内反馈
                            • 邮箱：support@voiceaccount.app
                            
                            感谢您选择使用语音记账应用！
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

struct AgreementSectionView: View {
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
    UserAgreementView()
}

