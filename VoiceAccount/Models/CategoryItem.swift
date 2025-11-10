//
//  CategoryItem.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import Foundation
import SwiftUI
import Combine

// 可编码的分类项
struct CategoryItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var isBuiltIn: Bool
    
    init(id: UUID = UUID(), name: String, iconName: String, colorHex: String, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    var backgroundColor: Color {
        color.opacity(0.15)
    }
}

// 分类管理器
class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    @Published var allCategories: [CategoryItem] = []
    
    private let saveKey = "AllCategories"
    
    init() {
        loadCategories()
        // 如果是首次启动，初始化默认分类
        if allCategories.isEmpty {
            initializeDefaultCategories()
        }
    }
    
    private func initializeDefaultCategories() {
        allCategories = ExpenseCategory.allCases.map { category in
            CategoryItem(
                name: category.rawValue,
                iconName: category.icon,
                colorHex: category.color.toHex() ?? "#3B82F6",
                isBuiltIn: true
            )
        }
        saveCategories()
    }
    
    func addCategory(_ category: CategoryItem) {
        allCategories.append(category)
        saveCategories()
    }
    
    func updateCategory(_ category: CategoryItem) {
        if let index = allCategories.firstIndex(where: { $0.id == category.id }) {
            allCategories[index] = category
            saveCategories()
        }
    }
    
    func deleteCategory(_ category: CategoryItem) {
        allCategories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(allCategories) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CategoryItem].self, from: data) {
            allCategories = decoded
        }
    }
}

// Color 扩展
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
    
    func toHex() -> String? {
        // 直接使用 CGColor 来避免递归调用 UIColor(_ color: Color)
        let environment = EnvironmentValues()
        let resolvedColor = self.resolve(in: environment)
        guard let components = resolvedColor.cgColor.components, components.count >= 3 else {
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
}

