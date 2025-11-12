//
//  KeychainHelper.swift
//  VoiceAccount
//
//  Created for secure token storage
//

import Foundation
import Security

/// Helper class for securely storing sensitive data in the iOS Keychain
class KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Keys
    private enum Keys {
        static let accessToken = "com.voiceaccount.accessToken"
        static let refreshToken = "com.voiceaccount.refreshToken"
        static let userId = "com.voiceaccount.userId"
        static let userEmail = "com.voiceaccount.userEmail"
    }

    // MARK: - Public Methods

    /// Save access token to Keychain
    func saveAccessToken(_ token: String) {
        save(token, forKey: Keys.accessToken)
    }

    /// Get access token from Keychain
    func getAccessToken() -> String? {
        return get(forKey: Keys.accessToken)
    }

    /// Save refresh token to Keychain
    func saveRefreshToken(_ token: String) {
        save(token, forKey: Keys.refreshToken)
    }

    /// Get refresh token from Keychain
    func getRefreshToken() -> String? {
        return get(forKey: Keys.refreshToken)
    }

    /// Save user ID to Keychain
    func saveUserId(_ userId: String) {
        save(userId, forKey: Keys.userId)
    }

    /// Get user ID from Keychain
    func getUserId() -> String? {
        return get(forKey: Keys.userId)
    }

    /// Save user email to Keychain
    func saveUserEmail(_ email: String) {
        save(email, forKey: Keys.userEmail)
    }

    /// Get user email from Keychain
    func getUserEmail() -> String? {
        return get(forKey: Keys.userEmail)
    }

    /// Clear all authentication data from Keychain
    func clearAll() {
        delete(forKey: Keys.accessToken)
        delete(forKey: Keys.refreshToken)
        delete(forKey: Keys.userId)
        delete(forKey: Keys.userEmail)
    }

    // MARK: - Private Methods

    /// Save string value to Keychain
    private func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Check if item already exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        // Delete existing item if present
        SecItemDelete(query as CFDictionary)

        // Add new item
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)

        if status != errSecSuccess {
            print("KeychainHelper: Failed to save \(key) - Status: \(status)")
        }
    }

    /// Get string value from Keychain
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                print("KeychainHelper: Failed to retrieve \(key) - Status: \(status)")
            }
            return nil
        }

        return value
    }

    /// Delete value from Keychain
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            print("KeychainHelper: Failed to delete \(key) - Status: \(status)")
        }
    }
}
