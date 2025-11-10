//
//  ThemeManager.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI
import Combine

// 外观模式
enum AppearanceMode: String, CaseIterable {
    case light = "白天"
    case dark = "深夜"
    case system = "跟随系统"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// 主题颜色配置
struct ThemeColors: Codable, Equatable {
    var colors: [String] // 渐变色的十六进制数组
    
    static let defaultLight = ThemeColors(
        colors: ["#FFF5E6", "#FFE0B2", "#FFCCBC", "#FFD1DC"]
    )
    
    static let defaultDark = ThemeColors(
        colors: ["#1A1A2E", "#16213E", "#0F3460", "#533483"]
    )
    
    var gradient: LinearGradient {
        let swiftUIColors = colors.compactMap { Color(hex: $0) }
        return LinearGradient(
            colors: swiftUIColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// 预设主题
struct PresetTheme: Identifiable {
    let id = UUID()
    let name: String
    let lightColors: ThemeColors
    let darkColors: ThemeColors
    
    static let presets: [PresetTheme] = [
        PresetTheme(
            name: "默认",
            lightColors: ThemeColors.defaultLight,
            darkColors: ThemeColors.defaultDark
        ),
        PresetTheme(
            name: "海洋",
            lightColors: ThemeColors(colors: ["#E0F7FA", "#B2EBF2", "#80DEEA", "#4DD0E1"]),
            darkColors: ThemeColors(colors: ["#006064", "#00838F", "#0097A7", "#00ACC1"])
        ),
        PresetTheme(
            name: "森林",
            lightColors: ThemeColors(colors: ["#F1F8E9", "#DCEDC8", "#C5E1A5", "#AED581"]),
            darkColors: ThemeColors(colors: ["#1B5E20", "#2E7D32", "#388E3C", "#43A047"])
        ),
        PresetTheme(
            name: "薰衣草",
            lightColors: ThemeColors(colors: ["#F3E5F5", "#E1BEE7", "#CE93D8", "#BA68C8"]),
            darkColors: ThemeColors(colors: ["#4A148C", "#6A1B9A", "#7B1FA2", "#8E24AA"])
        ),
        PresetTheme(
            name: "日落",
            lightColors: ThemeColors(colors: ["#FFF3E0", "#FFE0B2", "#FFCC80", "#FFB74D"]),
            darkColors: ThemeColors(colors: ["#E65100", "#EF6C00", "#F57C00", "#FB8C00"])
        ),
        PresetTheme(
            name: "樱花",
            lightColors: ThemeColors(colors: ["#FCE4EC", "#F8BBD0", "#F48FB1", "#F06292"]),
            darkColors: ThemeColors(colors: ["#880E4F", "#AD1457", "#C2185B", "#D81B60"])
        )
    ]
}

// 自定义主题
struct CustomTheme: Identifiable, Codable {
    let id: UUID
    var name: String
    var lightColors: ThemeColors
    var darkColors: ThemeColors
    
    init(id: UUID = UUID(), name: String, lightColors: ThemeColors, darkColors: ThemeColors) {
        self.id = id
        self.name = name
        self.lightColors = lightColors
        self.darkColors = darkColors
    }
}

// 主题管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    
    @Published var lightTheme: ThemeColors {
        didSet {
            saveTheme(lightTheme, key: "lightTheme")
        }
    }
    
    @Published var darkTheme: ThemeColors {
        didSet {
            saveTheme(darkTheme, key: "darkTheme")
        }
    }
    
    @Published var customThemes: [CustomTheme] = [] {
        didSet {
            saveCustomThemes()
        }
    }
    
    @Published var selectedThemeId: String? {
        didSet {
            UserDefaults.standard.set(selectedThemeId, forKey: "selectedThemeId")
        }
    }
    
    private init() {
        // 加载外观模式
        if let modeString = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceMode(rawValue: modeString) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .system
        }
        
        // 加载主题颜色
        self.lightTheme = ThemeManager.loadTheme(key: "lightTheme") ?? .defaultLight
        self.darkTheme = ThemeManager.loadTheme(key: "darkTheme") ?? .defaultDark
        
        // 加载自定义主题
        self.customThemes = ThemeManager.loadCustomThemes()
        
        // 加载选中的主题 ID
        self.selectedThemeId = UserDefaults.standard.string(forKey: "selectedThemeId")
    }
    
    func currentTheme(for colorScheme: ColorScheme) -> ThemeColors {
        // 根据外观模式决定使用哪个主题
        switch appearanceMode {
        case .light:
            return lightTheme
        case .dark:
            return darkTheme
        case .system:
            return colorScheme == .dark ? darkTheme : lightTheme
        }
    }
    
    // 获取当前应该显示的主题（不依赖 Environment colorScheme）
    var currentDisplayTheme: ThemeColors {
        switch appearanceMode {
        case .light:
            return lightTheme
        case .dark:
            return darkTheme
        case .system:
            // 跟随系统时，需要从 Environment 获取，所以这里默认返回 light
            // 实际使用时应该用 currentTheme(for:) 方法
            return lightTheme
        }
    }
    
    private func saveTheme(_ theme: ThemeColors, key: String) {
        if let encoded = try? JSONEncoder().encode(theme) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private static func loadTheme(key: String) -> ThemeColors? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let theme = try? JSONDecoder().decode(ThemeColors.self, from: data) else {
            return nil
        }
        return theme
    }
    
    func applyPreset(_ preset: PresetTheme) {
        lightTheme = preset.lightColors
        darkTheme = preset.darkColors
        selectedThemeId = "preset_\(preset.name)"
    }
    
    func applyCustomTheme(_ theme: CustomTheme) {
        lightTheme = theme.lightColors
        darkTheme = theme.darkColors
        selectedThemeId = theme.id.uuidString
    }
    
    func addCustomTheme(_ theme: CustomTheme) {
        customThemes.append(theme)
    }
    
    func updateCustomTheme(_ theme: CustomTheme) {
        if let index = customThemes.firstIndex(where: { $0.id == theme.id }) {
            customThemes[index] = theme
            // 如果当前选中的是这个主题，需要更新
            if selectedThemeId == theme.id.uuidString {
                applyCustomTheme(theme)
            }
        }
    }
    
    func deleteCustomTheme(_ theme: CustomTheme) {
        customThemes.removeAll { $0.id == theme.id }
        // 如果删除的是当前选中的主题，重置为默认主题
        if selectedThemeId == theme.id.uuidString {
            applyPreset(PresetTheme.presets[0])
        }
    }
    
    private func saveCustomThemes() {
        if let encoded = try? JSONEncoder().encode(customThemes) {
            UserDefaults.standard.set(encoded, forKey: "customThemes")
        }
    }
    
    private static func loadCustomThemes() -> [CustomTheme] {
        guard let data = UserDefaults.standard.data(forKey: "customThemes"),
              let themes = try? JSONDecoder().decode([CustomTheme].self, from: data) else {
            return []
        }
        return themes
    }
    
    func isPresetSelected(_ preset: PresetTheme) -> Bool {
        return selectedThemeId == "preset_\(preset.name)" &&
               lightTheme == preset.lightColors &&
               darkTheme == preset.darkColors
    }
    
    func isCustomThemeSelected(_ theme: CustomTheme) -> Bool {
        return selectedThemeId == theme.id.uuidString
    }
}

