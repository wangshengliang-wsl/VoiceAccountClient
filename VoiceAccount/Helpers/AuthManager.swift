//
//  AuthManager.swift
//  VoiceAccount
//
//  Manages user authentication using Supabase Auth
//

import Foundation
import Combine
import Supabase

enum AuthError: LocalizedError {
    case notConfigured
    case invalidCredentials
    case networkError(String)
    case tokenExpired
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please check SupabaseConfig.swift"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let message):
            return "Network error: \(message)"
        case .tokenExpired:
            return "Your session has expired. Please sign in again"
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }
}

/// Manages user authentication and session state
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var supabase: SupabaseClient?
    private var cancellables = Set<AnyCancellable>()
    private var tokenRefreshTimer: Timer?

    private init() {
        initializeSupabase()
        checkAuthStatus()
    }

    // MARK: - Initialization

    private func initializeSupabase() {
        guard SupabaseConfig.isConfigured else {
            print("⚠️ Supabase not configured. Please update SupabaseConfig.swift")
            return
        }

        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            print("❌ Invalid Supabase URL: \(SupabaseConfig.supabaseURL)")
            errorMessage = "Failed to create Supabase client: Invalid URL configuration"
            return
        }

        // Configure Supabase client for SDK v2.x
        // Note: SDK v2.x uses non-throwing initializer with default configuration
        supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        print("✅ Supabase client initialized successfully")
    }

    // MARK: - Authentication Status

    /// Check if user is currently authenticated
    private func checkAuthStatus() {
        Task {
            do {
                guard let supabase = supabase else {
                    isAuthenticated = false
                    return
                }

                // Try to get current session
                if let session = try? await supabase.auth.session {
                    self.currentUser = session.user
                    self.isAuthenticated = true

                    // Save user info to Keychain
                    KeychainHelper.shared.saveUserId(session.user.id.uuidString)
                    KeychainHelper.shared.saveUserEmail(session.user.email ?? "")
                    KeychainHelper.shared.saveAccessToken(session.accessToken)

                    // Start token refresh timer
                    startTokenRefreshTimer()

                    print("✅ User is authenticated: \(session.user.email ?? "unknown")")
                } else {
                    self.isAuthenticated = false
                }
            } catch {
                print("⚠️ No active session: \(error)")
                self.isAuthenticated = false
            }
        }
    }

    // MARK: - Sign Up

    /// Register a new user with email and password
    func signUp(email: String, password: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.notConfigured
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )

            print("✅ Sign up response received")

            // Response has optional session
            if let session = response.session {
                self.currentUser = session.user
                self.isAuthenticated = true

                // Save to Keychain
                KeychainHelper.shared.saveUserId(session.user.id.uuidString)
                KeychainHelper.shared.saveUserEmail(email)
                KeychainHelper.shared.saveAccessToken(session.accessToken)

                // Start token refresh
                startTokenRefreshTimer()

                print("✅ Sign up successful with immediate session: \(email)")
            } else {
                print("⚠️ Sign up successful but email confirmation required: \(email)")
                errorMessage = "注册成功！请检查邮箱完成验证后再登录。"
            }

            isLoading = false
        } catch {
            isLoading = false

            // Log detailed error for debugging
            print("❌ Sign up failed:")
            print("   Error: \(error)")
            print("   Localized: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Domain: \(nsError.domain)")
                print("   Code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }

            errorMessage = error.localizedDescription
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Sign In

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.notConfigured
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            self.currentUser = session.user
            self.isAuthenticated = true

            // Save to Keychain
            KeychainHelper.shared.saveUserId(session.user.id.uuidString)
            KeychainHelper.shared.saveUserEmail(email)
            KeychainHelper.shared.saveAccessToken(session.accessToken)

            // Start token refresh
            startTokenRefreshTimer()

            print("✅ Sign in successful: \(email)")

            isLoading = false
        } catch {
            isLoading = false

            // Log detailed error for debugging
            print("❌ Sign in failed:")
            print("   Error: \(error)")
            print("   Localized: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Domain: \(nsError.domain)")
                print("   Code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }

            // Check for specific error types
            let errorDesc = error.localizedDescription.lowercased()
            if errorDesc.contains("email") || errorDesc.contains("not found") || errorDesc.contains("invalid") {
                errorMessage = "邮箱或密码错误。如果还没有账号，请先注册。"
                throw AuthError.invalidCredentials
            } else if errorDesc.contains("network") || errorDesc.contains("connection") {
                errorMessage = "网络连接失败，请检查网络设置"
                throw AuthError.networkError(error.localizedDescription)
            } else {
                errorMessage = error.localizedDescription
                throw AuthError.unknown(error.localizedDescription)
            }
        }
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() async throws {
        guard let supabase = supabase else {
            throw AuthError.notConfigured
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.signOut()

            // Clear local state
            self.currentUser = nil
            self.isAuthenticated = false

            // Clear Keychain
            KeychainHelper.shared.clearAll()

            // Stop token refresh
            stopTokenRefreshTimer()

            print("✅ Sign out successful")
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Password Reset

    /// Send password reset email
    func resetPassword(email: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.notConfigured
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("✅ Password reset email sent to: \(email)")
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Token Management

    /// Get current access token
    func getAccessToken() async throws -> String {
        guard let supabase = supabase else {
            throw AuthError.notConfigured
        }

        do {
            if let session = try? await supabase.auth.session {
                KeychainHelper.shared.saveAccessToken(session.accessToken)
                return session.accessToken
            } else {
                throw AuthError.tokenExpired
            }
        } catch {
            throw AuthError.tokenExpired
        }
    }

    /// Refresh access token
    private func refreshToken() async {
        guard let supabase = supabase else { return }

        do {
            if let session = try? await supabase.auth.session {
                KeychainHelper.shared.saveAccessToken(session.accessToken)
                print("✅ Token refreshed successfully")
            } else {
                print("⚠️ Failed to refresh token")
                await signOutLocal()
            }
        } catch {
            print("⚠️ Failed to refresh token: \(error)")
            // If refresh fails, sign out user
            await signOutLocal()
        }
    }

    /// Local sign out (no API call)
    private func signOutLocal() {
        self.currentUser = nil
        self.isAuthenticated = false
        KeychainHelper.shared.clearAll()
        stopTokenRefreshTimer()
    }

    // MARK: - Token Refresh Timer

    private func startTokenRefreshTimer() {
        // Refresh token every 50 minutes (tokens expire after 60 minutes)
        stopTokenRefreshTimer()

        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: 50 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshToken()
            }
        }
    }

    private func stopTokenRefreshTimer() {
        tokenRefreshTimer?.invalidate()
        tokenRefreshTimer = nil
    }

    // MARK: - User Info

    var userId: String? {
        return currentUser?.id.uuidString ?? KeychainHelper.shared.getUserId()
    }

    var userEmail: String? {
        return currentUser?.email ?? KeychainHelper.shared.getUserEmail()
    }
}
