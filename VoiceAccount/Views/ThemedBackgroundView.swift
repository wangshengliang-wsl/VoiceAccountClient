//
//  ThemedBackgroundView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI

// MARK: - Themed Background View

struct ThemedBackgroundView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var systemColorScheme
    
    var body: some View {
        // 基础渐变背景
        // 根据外观模式决定使用哪个主题
        Group {
            switch themeManager.appearanceMode {
            case .light:
                themeManager.lightTheme.gradient
            case .dark:
                themeManager.darkTheme.gradient
            case .system:
                themeManager.currentTheme(for: systemColorScheme).gradient
            }
        }
        .ignoresSafeArea()
    }
}


#Preview {
    ThemedBackgroundView()
        .environmentObject(ThemeManager.shared)
}

