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
            MainTabView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.appearanceMode.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
