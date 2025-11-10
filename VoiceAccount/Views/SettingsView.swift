//
//  SettingsView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI
import SwiftData
import Combine

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [Expense]
    @StateObject private var categoryManager = CategoryManager()
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showingCurrencyPicker = false
    @State private var showingCategoryManager = false
    @State private var showingClearDataAlert = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var exportMessage = ""
    @State private var showingExportAlert = false
    @State private var showingPrivacyPolicy = false
    @State private var showingUserAgreement = false
    @State private var showingThemeSettings = false
    
    // 根据 categoryManager 中的所有分类来统计
    var categoryCounts: [(name: String, count: Int, iconName: String, color: Color)] {
        categoryManager.allCategories.map { category in
            let count = expenses.filter { $0.category == category.name }.count
            return (category.name, count, category.iconName, category.color)
        }
    }
    
    var body: some View {
        ZStack {
            // Themed Background
            ThemedBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("设置")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Theme Settings
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                    .foregroundColor(.purple)
                                Text("主题设置")
                                    .font(.headline)
                            }
                            
                            Button(action: {
                                showingThemeSettings = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("外观与主题色")
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Text("当前: \(themeManager.appearanceMode.rawValue)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // 主题色预览
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: themeManager.lightTheme.colors.first ?? "#FFF5E6") ?? .orange)
                                            .frame(width: 20, height: 20)
                                        Circle()
                                            .fill(Color(hex: themeManager.darkTheme.colors.first ?? "#1A1A2E") ?? .indigo)
                                            .frame(width: 20, height: 20)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(.white.opacity(0.5))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        
                        // Currency Settings
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "yensign.circle.fill")
                                    .foregroundColor(.blue)
                                Text("货币设置")
                                    .font(.headline)
                            }
                            
                            Button(action: {
                                showingCurrencyPicker = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("货币单位")
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Text("选择您使用的货币")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(currencyManager.currentCurrency.symbol) \(currencyManager.currentCurrency.name)")
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(.white.opacity(0.5))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        
                        // Category Management
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.purple)
                                Text("分类管理")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    showingCategoryManager = true
                                }) {
                                    Text("管理")
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("所有分类（\(categoryCounts.count)个）")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(categoryCounts.prefix(3), id: \.name) { item in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(item.color.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: item.iconName)
                                            .font(.caption)
                                            .foregroundColor(item.color)
                                    }
                                    
                                    Text(item.name)
                                    
                                    Spacer()
                                    
                                    Text("\(item.count) 笔")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .background(.white.opacity(0.3))
                                .cornerRadius(12)
                            }
                            
                            if categoryCounts.count > 3 {
                                Text("还有 \(categoryCounts.count - 3) 个分类...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        
                        // Data Management
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .foregroundColor(.green)
                                Text("数据管理")
                                    .font(.headline)
                            }
                            
                            VStack(spacing: 12) {
                                Button(action: exportData) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("导出 CSV 数据")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .green.opacity(0.3), radius: 8)
                                }
                                
                                Button(action: {
                                    showingClearDataAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("清除所有数据")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.red, Color.red.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .red.opacity(0.3), radius: 8)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        
                        // About
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.gray)
                                Text("关于")
                                    .font(.headline)
                            }
                            
                            VStack(spacing: 0) {
                                SettingRowView(
                                    title: "版本",
                                    subtitle: "语音记账 v1.0.0",
                                    showChevron: false
                                )
                                
                                Divider()
                                    .padding(.leading)
                                
                                SettingRowView(
                                    title: "隐私政策",
                                    subtitle: "查看我们的隐私条款",
                                    showChevron: true,
                                    action: {
                                        showingPrivacyPolicy = true
                                    }
                                )
                                
                                Divider()
                                    .padding(.leading)
                                
                                SettingRowView(
                                    title: "用户协议",
                                    subtitle: "查看服务条款",
                                    showChevron: true,
                                    action: {
                                        showingUserAgreement = true
                                    }
                                )
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
            }
        }
        .sheet(isPresented: $showingThemeSettings) {
            ThemeSettingsView(themeManager: themeManager)
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerView(currencyManager: currencyManager)
        }
        .sheet(isPresented: $showingCategoryManager) {
            CategoryManagerView(categoryManager: categoryManager)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingUserAgreement) {
            UserAgreementView()
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            if let url = shareURL {
                try? FileManager.default.removeItem(at: url)
                shareURL = nil
            }
        }) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .alert("数据导出", isPresented: $showingExportAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(exportMessage)
        }
        .alert("清除所有数据", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("此操作将永久删除所有记账数据，且无法恢复。您确定要继续吗？")
        }
    }
    
    private func exportData() {
        if expenses.isEmpty {
            exportMessage = "没有数据可以导出"
            showingExportAlert = true
            return
        }
        
        guard let url = CSVExporter.exportExpenses(expenses) else {
            exportMessage = "导出失败，请重试"
            showingExportAlert = true
            return
        }
        
        shareURL = url
        showingShareSheet = true
    }
    
    private func clearAllData() {
        for expense in expenses {
            modelContext.delete(expense)
        }
    }
}

struct SettingRowView: View {
    let title: String
    let subtitle: String
    var showChevron: Bool = true
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding()
        }
    }
}

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var currencyManager: CurrencyManager
    
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
                
                List {
                    ForEach(CurrencyManager.currencies, id: \.code) { currency in
                        Button(action: {
                            currencyManager.setCurrency(currency)
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                Text(currency.symbol)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currency.name)
                                        .fontWeight(.medium)
                                    Text(currency.code)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if currencyManager.currentCurrency.code == currency.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("选择货币")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 分类管理视图
struct CategoryManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var categoryManager: CategoryManager
    @State private var showingAddEdit = false
    @State private var editingCategory: CategoryItem?
    
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
                
                List {
                    Section("所有分类（\(categoryManager.allCategories.count)个）") {
                        ForEach(categoryManager.allCategories) { category in
                            CategoryRowView(
                                iconName: category.iconName,
                                name: category.name,
                                color: category.color,
                                backgroundColor: category.backgroundColor,
                                isBuiltIn: category.isBuiltIn,
                                onEdit: {
                                    editingCategory = category
                                    showingAddEdit = true
                                }
                            )
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let category = categoryManager.allCategories[index]
                                categoryManager.deleteCategory(category)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("分类管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        editingCategory = nil
                        showingAddEdit = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddEdit) {
                AddEditCategoryView(
                    category: editingCategory,
                    categoryManager: categoryManager
                )
            }
        }
    }
}

struct CategoryRowView: View {
    let iconName: String
    let name: String
    let color: Color
    let backgroundColor: Color
    let isBuiltIn: Bool
    var onEdit: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                if isBuiltIn {
                    Text("默认分类")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.white.opacity(0.5))
    }
}

// 添加/编辑分类视图
struct AddEditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    let category: CategoryItem?
    @ObservedObject var categoryManager: CategoryManager
    
    @State private var name = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColorHex = "#3B82F6"
    
    let icons = [
        "tag.fill", "fork.knife", "car.fill", "bus.fill", "cart.fill",
        "bag.fill", "gamecontroller.fill", "house.fill", "heart.fill",
        "book.fill", "airplane", "gift.fill", "dumbbell", "laptopcomputer",
        "music.note", "cup.and.saucer.fill", "bicycle", "camera.fill",
        "theatermasks.fill", "paintbrush.fill", "wrench.fill", "bolt.fill"
    ]
    
    let colors = [
        "#3B82F6", "#10B981", "#8B5CF6", "#F59E0B", "#EF4444",
        "#6366F1", "#14B8A6", "#F97316", "#EC4899", "#84CC16",
        "#06B6D4", "#F43F5E", "#8B5CF6", "#A855F7", "#D946EF"
    ]
    
    var isEditing: Bool {
        category != nil
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
                
                Form {
                    Section("分类名称") {
                        TextField("输入分类名称", text: $name)
                    }
                    .listRowBackground(Color.white.opacity(0.5))
                    
                    Section("选择图标") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: icon)
                                            .foregroundColor(selectedIcon == icon ? .white : .gray)
                                            .font(.system(size: 20))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.5))
                    
                    Section("选择颜色") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                            ForEach(colors, id: \.self) { colorHex in
                                Button(action: {
                                    selectedColorHex = colorHex
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: colorHex) ?? .blue)
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColorHex == colorHex ? Color.white : Color.clear, lineWidth: 3)
                                            )
                                            .shadow(color: selectedColorHex == colorHex ? .black.opacity(0.3) : .clear, radius: 4)
                                        
                                        if selectedColorHex == colorHex {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.5))
                    
                    // 预览
                    Section("预览") {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill((Color(hex: selectedColorHex) ?? .blue).opacity(0.15))
                                    .frame(width: 50, height: 50)
                                Image(systemName: selectedIcon)
                                    .foregroundColor(Color(hex: selectedColorHex) ?? .blue)
                                    .font(.title3)
                            }
                            
                            Text(name.isEmpty ? "分类名称" : name)
                                .font(.headline)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white.opacity(0.5))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "编辑分类" : "添加分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let category = category {
                    name = category.name
                    selectedIcon = category.iconName
                    selectedColorHex = category.colorHex
                }
            }
        }
    }
    
    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if let category = category {
            // 编辑现有分类
            let updated = CategoryItem(
                id: category.id,
                name: trimmedName,
                iconName: selectedIcon,
                colorHex: selectedColorHex,
                isBuiltIn: false
            )
            categoryManager.updateCategory(updated)
        } else {
            // 添加新分类
            let newCategory = CategoryItem(
                name: trimmedName,
                iconName: selectedIcon,
                colorHex: selectedColorHex,
                isBuiltIn: false
            )
            categoryManager.addCategory(newCategory)
        }
        
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Expense.self, inMemory: true)
        .environmentObject(ThemeManager.shared)
}
