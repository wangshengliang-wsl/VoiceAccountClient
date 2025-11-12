//
//  VoiceAccountApp.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI
import SwiftData

@main
struct VoiceAccountApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authManager = AuthManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    // Authenticated: Show main app
                    MainTabView()
                        .environmentObject(themeManager)
                        .environmentObject(authManager)
                        .preferredColorScheme(themeManager.appearanceMode.colorScheme)
                        .modelContainer(sharedModelContainer)
                } else {
                    // Not authenticated: Show auth flow
                    AuthContainerView()
                        .environmentObject(themeManager)
                        .environmentObject(authManager)
                        .preferredColorScheme(themeManager.appearanceMode.colorScheme)
                }
            }
        }
    }
}
