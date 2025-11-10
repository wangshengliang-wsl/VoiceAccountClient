//
//  Expense.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var amount: Double
    var title: String
    var category: String  // 存储分类名称
    var date: Date
    var notes: String?
    
    init(amount: Double, title: String, categoryName: String, date: Date = Date(), notes: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.title = title
        self.category = categoryName
        self.date = date
        self.notes = notes
    }
    
    // 兼容旧的 ExpenseCategory 枚举
    var expenseCategory: ExpenseCategory {
        ExpenseCategory(rawValue: category) ?? .other
    }
}

