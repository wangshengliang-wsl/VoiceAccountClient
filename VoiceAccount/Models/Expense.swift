//
//  Expense.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import Foundation
import SwiftData

/// Sync status for cloud synchronization
enum SyncStatus: String, Codable {
    case pending    // Waiting to be synced
    case synced     // Successfully synced to cloud
    case failed     // Sync failed, needs retry
}

@Model
final class Expense {
    var id: UUID
    var amount: Double
    var title: String
    var category: String  // 存储分类名称
    var date: Date
    var notes: String?

    // Cloud sync fields
    var userId: String?              // Supabase Auth user ID
    var createdAt: Date              // Creation timestamp
    var updatedAt: Date              // Last update timestamp
    var syncStatusRaw: String        // Stored as String for SwiftData compatibility

    // Computed property for sync status
    var syncStatus: SyncStatus {
        get {
            SyncStatus(rawValue: syncStatusRaw) ?? .pending
        }
        set {
            syncStatusRaw = newValue.rawValue
        }
    }

    init(amount: Double, title: String, categoryName: String, date: Date = Date(), notes: String? = nil, userId: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.title = title
        self.category = categoryName
        self.date = date
        self.notes = notes
        self.userId = userId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatusRaw = SyncStatus.pending.rawValue
    }

    // 兼容旧的 ExpenseCategory 枚举
    var expenseCategory: ExpenseCategory {
        ExpenseCategory(rawValue: category) ?? .other
    }

    // Update the updatedAt timestamp
    func markAsUpdated() {
        self.updatedAt = Date()
        self.syncStatus = .pending
    }

    // Mark as synced successfully
    func markAsSynced() {
        self.syncStatus = .synced
    }

    // Mark as sync failed
    func markAsFailed() {
        self.syncStatus = .failed
    }
}

