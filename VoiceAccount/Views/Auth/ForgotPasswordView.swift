//
//  ForgotPasswordView.swift
//  VoiceAccount
//
//  Password reset view
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Themed background
            ThemedBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)

                    // Icon
                    Image(systemName: "key.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.bottom, 20)

                    // Title and Description
                    VStack(spacing: 12) {
                        Text("重置密码")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)

                        Text("输入您的邮箱地址\n我们将向您发送重置密码的链接")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)

                    // Email Field
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("邮箱")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                TextField("请输入邮箱", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }

                        // Send Button
                        Button(action: sendResetLink) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 20))
                                    Text("发送重置链接")
                                        .fontWeight(.bold)
                                        .font(.system(size: 18))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: isEmailValid ?
                                        [Color.orange, Color.orange.opacity(0.8)] :
                                        [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(authManager.isLoading || !isEmailValid)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("邮件已发送", isPresented: $showSuccess) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text("我们已向 \(email) 发送了重置密码的链接，请查收邮件并按照指示操作。")
        }
        .alert("发送失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isEmailValid: Bool {
        !email.isEmpty && email.contains("@")
    }

    private func sendResetLink() {
        Task {
            do {
                try await authManager.resetPassword(email: email)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    NavigationView {
        ForgotPasswordView()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}
