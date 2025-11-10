//
//  SampleDataGenerator.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import Foundation
import SwiftData

class SampleDataGenerator {
    static func generateSampleData(modelContext: ModelContext) {
        // 清除现有数据
        let descriptor = FetchDescriptor<Expense>()
        if let existingExpenses = try? modelContext.fetch(descriptor), !existingExpenses.isEmpty {
            return // 如果已有数据，不生成示例数据
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 今天的记录
        let todayExpenses = [
            Expense(amount: 45.0, title: "午餐", categoryName: "餐饮", date: calendar.date(byAdding: .hour, value: -6, to: now)!),
            Expense(amount: 28.0, title: "咖啡", categoryName: "餐饮", date: calendar.date(byAdding: .hour, value: -11, to: now)!),
            Expense(amount: 6.0, title: "地铁", categoryName: "交通", date: calendar.date(byAdding: .hour, value: -12, to: now)!)
        ]
        
        // 昨天的记录
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let yesterdayExpenses = [
            Expense(amount: 58.0, title: "电影票", categoryName: "娱乐", date: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: yesterday)!),
            Expense(amount: 85.5, title: "晚餐", categoryName: "餐饮", date: calendar.date(bySettingHour: 18, minute: 15, second: 0, of: yesterday)!),
            Expense(amount: 2.0, title: "公交", categoryName: "交通", date: calendar.date(bySettingHour: 17, minute: 45, second: 0, of: yesterday)!),
            Expense(amount: 42.0, title: "午餐", categoryName: "餐饮", date: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)!),
            Expense(amount: 32.0, title: "咖啡", categoryName: "餐饮", date: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: yesterday)!)
        ]
        
        // 前天的记录
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        let twoDaysAgoExpenses = [
            Expense(amount: 128.8, title: "购物", categoryName: "购物", date: calendar.date(bySettingHour: 15, minute: 20, second: 0, of: twoDaysAgo)!),
            Expense(amount: 68.0, title: "午餐", categoryName: "餐饮", date: calendar.date(bySettingHour: 13, minute: 15, second: 0, of: twoDaysAgo)!),
            Expense(amount: 38.0, title: "打车", categoryName: "交通", date: calendar.date(bySettingHour: 11, minute: 45, second: 0, of: twoDaysAgo)!)
        ]
        
        // 本月其他记录
        var otherExpenses: [Expense] = []
        for dayOffset in 3...10 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let randomExpenses = [
                Expense(amount: Double.random(in: 30...80), title: "午餐", categoryName: "餐饮", date: calendar.date(bySettingHour: 12, minute: Int.random(in: 0...59), second: 0, of: date)!),
                Expense(amount: Double.random(in: 20...40), title: "咖啡", categoryName: "餐饮", date: calendar.date(bySettingHour: 9, minute: Int.random(in: 0...59), second: 0, of: date)!),
                Expense(amount: Double.random(in: 5...20), title: "交通", categoryName: "交通", date: calendar.date(bySettingHour: 8, minute: Int.random(in: 0...59), second: 0, of: date)!)
            ]
            otherExpenses.append(contentsOf: randomExpenses)
        }
        
        // 插入所有示例数据
        let allExpenses = todayExpenses + yesterdayExpenses + twoDaysAgoExpenses + otherExpenses
        for expense in allExpenses {
            modelContext.insert(expense)
        }
        
        // 保存数据
        try? modelContext.save()
    }
}

