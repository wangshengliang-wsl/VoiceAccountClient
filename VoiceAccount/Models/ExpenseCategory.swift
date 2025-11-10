//
//  ExpenseCategory.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import Foundation
import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable {
    case dining = "餐饮"
    case transportation = "交通"
    case shopping = "购物"
    case entertainment = "娱乐"
    case medical = "医疗"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .dining: return "fork.knife"
        case .transportation: return "bus.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .medical: return "cross.case.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .dining: return Color.blue
        case .transportation: return Color.green
        case .shopping: return Color.purple
        case .entertainment: return Color.orange
        case .medical: return Color.red
        case .other: return Color.gray
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .dining: return Color.blue.opacity(0.1)
        case .transportation: return Color.green.opacity(0.1)
        case .shopping: return Color.purple.opacity(0.1)
        case .entertainment: return Color.orange.opacity(0.1)
        case .medical: return Color.red.opacity(0.1)
        case .other: return Color.gray.opacity(0.1)
        }
    }
}

