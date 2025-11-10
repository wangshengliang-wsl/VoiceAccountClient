//
//  CSVExporter.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class CSVExporter {
    static func exportExpenses(_ expenses: [Expense]) -> URL? {
        var csvText = "日期,时间,标题,分类,金额,备注\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        for expense in expenses.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: expense.date)
            let time = timeFormatter.string(from: expense.date)
            let title = expense.title.replacingOccurrences(of: ",", with: "，")
            let category = expense.category.replacingOccurrences(of: ",", with: "，")
            let amount = String(format: "%.2f", expense.amount)
            let notes = (expense.notes ?? "").replacingOccurrences(of: ",", with: "，")
            
            csvText += "\(date),\(time),\(title),\(category),\(amount),\(notes)\n"
        }
        
        let fileName = "语音记账_\(dateFormatter.string(from: Date())).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("CSV导出失败: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

