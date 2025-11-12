//
//  LoginView.swift
//  VoiceAccount
//
//  Login view for user authentication
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var rememberMe = true
    @State private var showError = false
    @State private var errorMessage = ""

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        ZStack {
            // Themed background
            ThemedBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 60)

                    // Logo/Title
                    VStack(spacing: 12) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                        Text("VoiceAccount")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)

                        Text("语音记账，轻松同步")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                    .padding(.bottom, 40)

                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
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
                                    .focused($focusedField, equals: .email)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("密码")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                if showPassword {
                                    TextField("请输入密码", text: $password)
                                        .focused($focusedField, equals: .password)
                                        .foregroundColor(.primary)
                                } else {
                                    SecureField("请输入密码", text: $password)
                                        .focused($focusedField, equals: .password)
                                        .foregroundColor(.primary)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }

                        // Remember Me & Forgot Password
                        HStack {
                            Button(action: { rememberMe.toggle() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                    Text("记住我")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            }
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                            Spacer()

                            NavigationLink(destination: ForgotPasswordView()) {
                                Text("忘记密码?")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .underline()
                            }
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)

                        // Login Button
                        Button(action: login) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 20))
                                    Text("登录")
                                        .fontWeight(.bold)
                                        .font(.system(size: 18))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: isFormValid ?
                                        [Color.blue, Color.blue.opacity(0.8)] :
                                        [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(authManager.isLoading || !isFormValid)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("登录失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }

    private func login() {
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                // Use the detailed error message from AuthManager if available
                if let authError = authManager.errorMessage, !authError.isEmpty {
                    errorMessage = authError
                } else {
                    errorMessage = error.localizedDescription
                }
                showError = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
        .environmentObject(ThemeManager.shared)
}
