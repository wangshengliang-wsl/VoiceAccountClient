//
//  RegisterView.swift
//  VoiceAccount
//
//  Registration view for new users
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreeToTerms = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword
    }

    var body: some View {
        ZStack {
            // Themed background
            ThemedBackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)

                    // Title
                    VStack(spacing: 12) {
                        Text("创建账户")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)

                        Text("注册后可跨设备同步数据")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                    .padding(.bottom, 30)

                    // Registration Form
                    VStack(spacing: 18) {
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
                                    TextField("至少6位字符", text: $password)
                                        .focused($focusedField, equals: .password)
                                        .foregroundColor(.primary)
                                } else {
                                    SecureField("至少6位字符", text: $password)
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

                            // Password strength indicator
                            if !password.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 4) {
                                        ForEach(0..<3) { index in
                                            Rectangle()
                                                .fill(passwordStrength > index ? strengthColor : Color.white.opacity(0.4))
                                                .frame(height: 4)
                                                .cornerRadius(2)
                                        }
                                    }

                                    Text(passwordStrengthText)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                                .padding(.top, 4)
                            }
                        }

                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("确认密码")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                            HStack(spacing: 12) {
                                Image(systemName: "lock.circle.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                if showConfirmPassword {
                                    TextField("再次输入密码", text: $confirmPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .foregroundColor(.primary)
                                } else {
                                    SecureField("再次输入密码", text: $confirmPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .foregroundColor(.primary)
                                }

                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

                            if !confirmPassword.isEmpty && password != confirmPassword {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text("密码不匹配")
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                        }

                        // Terms and Conditions
                        Button(action: { agreeToTerms.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: agreeToTerms ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))

                                HStack(spacing: 4) {
                                    Text("我同意")
                                    NavigationLink(destination: UserAgreementView()) {
                                        Text("用户协议")
                                            .underline()
                                    }
                                    Text("和")
                                    NavigationLink(destination: PrivacyPolicyView()) {
                                        Text("隐私政策")
                                            .underline()
                                    }
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            }
                        }
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)

                        // Register Button
                        Button(action: register) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "person.badge.plus.fill")
                                        .font(.system(size: 20))
                                    Text("注册")
                                        .fontWeight(.bold)
                                        .font(.system(size: 18))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: isFormValid ?
                                        [Color.green, Color.green.opacity(0.8)] :
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
        .navigationBarTitleDisplayMode(.inline)
        .alert("注册失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("注册成功", isPresented: $showSuccess) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreeToTerms
    }

    private var passwordStrength: Int {
        var strength = 0
        if password.count >= 6 { strength += 1 }
        if password.count >= 10 { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil &&
           password.rangeOfCharacter(from: .letters) != nil {
            strength += 1
        }
        return strength
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case 1: return .red
        case 2: return .yellow
        case 3: return .green
        default: return .white.opacity(0.3)
        }
    }

    private var passwordStrengthText: String {
        switch passwordStrength {
        case 1: return "弱"
        case 2: return "中"
        case 3: return "强"
        default: return ""
        }
    }

    private func register() {
        Task {
            do {
                try await authManager.signUp(email: email, password: password)

                // Check if authenticated (immediate login) or needs email verification
                if authManager.isAuthenticated {
                    // Immediate login success
                    dismiss()
                } else if let message = authManager.errorMessage, !message.isEmpty {
                    // Email verification required
                    successMessage = message
                    showSuccess = true
                } else {
                    // Default success message
                    successMessage = "注册成功！"
                    showSuccess = true
                }
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
    NavigationView {
        RegisterView()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}
