//
//  ColorPickerView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI

struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var themeColors: ThemeColors
    @State private var editingColors: [String]
    @State private var selectedColorIndex: Int = 0
    let title: String
    
    init(themeColors: Binding<ThemeColors>, title: String) {
        self._themeColors = themeColors
        self.title = title
        _editingColors = State(initialValue: themeColors.wrappedValue.colors)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 使用当前编辑的渐变作为背景
                currentGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 预览区域
                        previewSection
                        
                        // 颜色列表
                        colorListSection
                        
                        // 添加颜色按钮
                        addColorButton
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Current Gradient
    
    private var currentGradient: LinearGradient {
        let colors = editingColors.compactMap { Color(hex: $0) }
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                Text("预览效果")
                    .font(.headline)
            }
            
            ZStack {
                // 背景渐变
                RoundedRectangle(cornerRadius: 20)
                    .fill(currentGradient)
                
                // 示例文字
                VStack(spacing: 8) {
                    Text("示例内容")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("这是预览文字效果")
                        .font(.subheadline)
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 2)
            }
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 10)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    
    // MARK: - Color List Section
    
    private var colorListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(.purple)
                Text("渐变颜色 (\(editingColors.count))")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(editingColors.enumerated()), id: \.offset) { index, colorHex in
                    ColorRowView(
                        colorHex: colorHex,
                        index: index + 1,
                        onColorChange: { newColor in
                            editingColors[index] = newColor
                        },
                        onDelete: editingColors.count > 2 ? {
                            withAnimation {
                                _ = editingColors.remove(at: index)
                            }
                        } : nil
                    )
                    .environmentObject(themeManager)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    // MARK: - Add Color Button
    
    private var addColorButton: some View {
        Button(action: {
            withAnimation {
                // 添加一个新的颜色（随机或基于最后一个颜色的变体）
                let newColor = generateNewColor()
                editingColors.append(newColor)
            }
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("添加渐变色")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 8)
        }
        .disabled(editingColors.count >= 6) // 最多6个颜色
    }
    
    // MARK: - Helper Methods
    
    private func generateNewColor() -> String {
        // 生成一个随机颜色
        let hue = Double.random(in: 0...1)
        let saturation = Double.random(in: 0.5...1)
        let brightness = Double.random(in: 0.5...1)
        
        let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
        return color.toHex() ?? "#3B82F6"
    }
    
    private func saveChanges() {
        themeColors = ThemeColors(
            colors: editingColors
        )
    }
}

// MARK: - Color Row View

struct ColorRowView: View {
    let colorHex: String
    let index: Int
    let onColorChange: (String) -> Void
    let onDelete: (() -> Void)?
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showingColorPicker = false
    @State private var selectedColor: Color
    
    init(colorHex: String, index: Int, onColorChange: @escaping (String) -> Void, onDelete: (() -> Void)?) {
        self.colorHex = colorHex
        self.index = index
        self.onColorChange = onColorChange
        self.onDelete = onDelete
        _selectedColor = State(initialValue: Color(hex: colorHex) ?? .blue)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 颜色预览
            Button(action: {
                showingColorPicker = true
            }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("颜色 \(index)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(colorHex.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()
            }
            
            Spacer()
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white.opacity(0.3))
        .cornerRadius(12)
        .sheet(isPresented: $showingColorPicker) {
            SystemColorPickerView(
                selectedColor: $selectedColor,
                onSave: { newColor in
                    selectedColor = newColor
                    if let hex = UIColor(newColor).toHex() {
                        onColorChange(hex)
                    }
                }
            )
            .environmentObject(themeManager)
        }
    }
}

// MARK: - System Color Picker View

struct SystemColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedColor: Color
    let onSave: (Color) -> Void
    
    @State private var tempColor: Color
    
    init(selectedColor: Binding<Color>, onSave: @escaping (Color) -> Void) {
        self._selectedColor = selectedColor
        self.onSave = onSave
        _tempColor = State(initialValue: selectedColor.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主题背景
                ThemedBackgroundView()
                
                VStack(spacing: 24) {
                    // 颜色预览
                    RoundedRectangle(cornerRadius: 20)
                        .fill(tempColor)
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10)
                        .padding()
                    
                    // 系统颜色选择器
                    ColorPicker("选择颜色", selection: $tempColor)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onSave(tempColor)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - UIColor Extension

extension UIColor {
    func toHex() -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
    
    convenience init(_ color: Color) {
        // 使用 CGColor 来避免递归调用
        // SwiftUI Color 可以通过 CGColor 来获取颜色组件
        if #available(iOS 14.0, *) {
            // 使用环境值来解析颜色
            let environment = EnvironmentValues()
            let resolvedColor = color.resolve(in: environment)
            let cgColor = resolvedColor.cgColor
            let components = cgColor.components ?? []
            
            if components.count >= 4 {
                self.init(
                    red: components[0],
                    green: components[1],
                    blue: components[2],
                    alpha: components[3]
                )
            } else if components.count >= 3 {
                self.init(
                    red: components[0],
                    green: components[1],
                    blue: components[2],
                    alpha: 1.0
                )
            } else {
                self.init(white: 0.5, alpha: 1.0)
            }
        } else {
            // iOS 13 及以下版本的回退
            self.init(white: 0.5, alpha: 1.0)
        }
    }
}

#Preview {
    ColorPickerView(
        themeColors: .constant(ThemeColors.defaultLight),
        title: "自定义颜色"
    )
}

