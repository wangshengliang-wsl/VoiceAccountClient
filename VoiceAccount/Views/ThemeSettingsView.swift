//
//  ThemeSettingsView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var themeManager: ThemeManager
    @State private var selectedMode: AppearanceMode
    @State private var showingLightColorPicker = false
    @State private var showingDarkColorPicker = false
    @State private var showingAddCustomTheme = false
    @State private var editingCustomTheme: CustomTheme?
    
    init(themeManager: ThemeManager) {
        self.themeManager = themeManager
        _selectedMode = State(initialValue: themeManager.appearanceMode)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 根据外观模式决定使用哪个主题
                Group {
                    switch themeManager.appearanceMode {
                    case .light:
                        themeManager.lightTheme.gradient
                    case .dark:
                        themeManager.darkTheme.gradient
                    case .system:
                        themeManager.currentTheme(for: colorScheme).gradient
                    }
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 外观模式选择
                        appearanceModeSection
                        
                        // 预设主题
                        presetThemesSection
                        
                        // 自定义主题列表
                        customThemesListSection
                    }
                    .padding()
                }
            }
            .navigationTitle("主题设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomTheme) {
                AddCustomThemeView(themeManager: themeManager, editingTheme: editingCustomTheme)
            }
        }
    }
    
    // MARK: - Appearance Mode Section
    
    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                Text("外观模式")
                    .font(.headline)
            }
            
            HStack(spacing: 0) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                            themeManager.appearanceMode = mode
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: iconForMode(mode))
                                .font(.title3)
                            Text(mode.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedMode == mode ?
                                Color.white.opacity(0.9) :
                                Color.white.opacity(0.3)
                        )
                        .foregroundColor(
                            selectedMode == mode ? .primary : .secondary
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if mode != AppearanceMode.allCases.last {
                        Divider()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    private func iconForMode(_ mode: AppearanceMode) -> String {
        switch mode {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "iphone"
        }
    }
    
    // MARK: - Preset Themes Section
    
    private var presetThemesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(.blue)
                Text("预设主题")
                    .font(.headline)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PresetTheme.presets) { preset in
                        PresetThemeCard(
                            preset: preset,
                            isSelected: isPresetSelected(preset),
                            action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    themeManager.applyPreset(preset)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    private func isPresetSelected(_ preset: PresetTheme) -> Bool {
        return themeManager.isPresetSelected(preset)
    }
    
    // MARK: - Custom Themes List Section
    
    private var customThemesListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.orange)
                Text("自定义颜色")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    editingCustomTheme = nil
                    showingAddCustomTheme = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }
            
            if themeManager.customThemes.isEmpty {
                // 占位图
                VStack(spacing: 12) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无自定义颜色")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("点击右上角 + 号添加")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(themeManager.customThemes) { theme in
                        CustomThemeRow(
                            theme: theme,
                            isSelected: themeManager.isCustomThemeSelected(theme),
                            onSelect: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    themeManager.applyCustomTheme(theme)
                                }
                            },
                            onEdit: {
                                editingCustomTheme = theme
                                showingAddCustomTheme = true
                            },
                            onDelete: {
                                withAnimation {
                                    themeManager.deleteCustomTheme(theme)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// MARK: - Preset Theme Card

struct PresetThemeCard: View {
    let preset: PresetTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 双色预览
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(preset.lightColors.gradient)
                        .frame(width: 60, height: 60)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(preset.darkColors.gradient)
                        .frame(width: 60, height: 60)
                }
                
                Text(preset.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Theme Row

struct CustomThemeRow: View {
    let theme: CustomTheme
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Radio 单选框
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            
            // 主题信息
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.name)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .bold : .medium)
                            .foregroundColor(.primary)
                        
                        // 颜色预览
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.lightColors.gradient)
                                .frame(width: 40, height: 20)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.darkColors.gradient)
                                .frame(width: 40, height: 20)
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            // 编辑按钮
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(0.3))
        )
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add/Edit Custom Theme View

struct AddCustomThemeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var themeManager: ThemeManager
    let editingTheme: CustomTheme?
    
    @State private var themeName: String = ""
    @State private var lightColors: ThemeColors = ThemeColors.defaultLight
    @State private var darkColors: ThemeColors = ThemeColors.defaultDark
    @State private var showingLightColorPicker = false
    @State private var showingDarkColorPicker = false
    
    var isEditing: Bool {
        editingTheme != nil
    }
    
    init(themeManager: ThemeManager, editingTheme: CustomTheme?) {
        self.themeManager = themeManager
        self.editingTheme = editingTheme
        
        if let theme = editingTheme {
            _themeName = State(initialValue: theme.name)
            _lightColors = State(initialValue: theme.lightColors)
            _darkColors = State(initialValue: theme.darkColors)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.96, blue: 0.9),
                        Color(red: 1.0, green: 0.88, blue: 0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 名称输入
                        nameSection
                        
                        // 白天模式颜色
                        colorSection(
                            title: "白天模式颜色",
                            icon: "sun.max.fill",
                            iconColor: .orange,
                            colors: lightColors,
                            action: { showingLightColorPicker = true }
                        )
                        
                        // 深夜模式颜色
                        colorSection(
                            title: "深夜模式颜色",
                            icon: "moon.fill",
                            iconColor: .indigo,
                            colors: darkColors,
                            action: { showingDarkColorPicker = true }
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "编辑主题" : "新建主题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTheme()
                    }
                    .disabled(themeName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showingLightColorPicker) {
                ColorPickerView(themeColors: $lightColors, title: "白天模式颜色")
            }
            .sheet(isPresented: $showingDarkColorPicker) {
                ColorPickerView(themeColors: $darkColors, title: "深夜模式颜色")
            }
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.purple)
                Text("主题名称")
                    .font(.headline)
            }
            
            TextField("输入主题名称", text: $themeName)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(12)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    private func colorSection(title: String, icon: String, iconColor: Color, colors: ThemeColors, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
            }
            
            Button(action: action) {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colors.gradient)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white.opacity(0.4))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    private func saveTheme() {
        let trimmedName = themeName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if let editing = editingTheme {
            // 编辑现有主题
            let updated = CustomTheme(
                id: editing.id,
                name: trimmedName,
                lightColors: lightColors,
                darkColors: darkColors
            )
            themeManager.updateCustomTheme(updated)
        } else {
            // 添加新主题
            let newTheme = CustomTheme(
                name: trimmedName,
                lightColors: lightColors,
                darkColors: darkColors
            )
            themeManager.addCustomTheme(newTheme)
        }
        
        dismiss()
    }
}

#Preview {
    ThemeSettingsView(themeManager: ThemeManager.shared)
}

