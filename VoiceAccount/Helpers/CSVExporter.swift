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
    /// 转义CSV字段中的特殊字符
    private static func escapeCSVField(_ field: String) -> String {
        // 如果字段包含逗号、双引号或换行符，需要用双引号包裹
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            // 将字段中的双引号转义为两个双引号
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    static func exportExpenses(_ expenses: [Expense]) -> URL? {
        // 添加UTF-8 BOM以确保Excel等软件正确识别编码
        var csvText = "\u{FEFF}日期,时间,标题,分类,金额,备注\n"

        // CSV内容的日期格式 (使用斜杠,Excel更容易识别)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        dateFormatter.locale = Locale(identifier: "zh_CN")

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "zh_CN")

        for expense in expenses.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: expense.date)
            let time = timeFormatter.string(from: expense.date)
            // 转义CSV特殊字符
            let title = escapeCSVField(expense.title)
            let category = escapeCSVField(expense.category)
            let amount = String(format: "%.2f", expense.amount)
            let notes = escapeCSVField(expense.notes ?? "")

            csvText += "\(date),\(time),\(title),\(category),\(amount),\(notes)\n"
        }

        // 文件名的日期格式 (使用短横线,避免斜杠被当作路径分隔符)
        let fileNameDateFormatter = DateFormatter()
        fileNameDateFormatter.dateFormat = "yyyy-MM-dd"
        fileNameDateFormatter.locale = Locale(identifier: "zh_CN")

        let fileName = "语音记账_\(fileNameDateFormatter.string(from: Date())).csv"
        let tempDir = FileManager.default.temporaryDirectory
        let path = tempDir.appendingPathComponent(fileName)

        do {
            // 如果文件已存在,先删除 (使用URL对象,不需要转换路径)
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
                print("🗑️ 已删除旧文件")
            }

            try csvText.write(to: path, atomically: true, encoding: .utf8)

            // 获取文件路径字符串用于日志输出
            let pathString: String
            if #available(iOS 16.0, *) {
                pathString = path.path()
            } else {
                pathString = path.path
            }
            print("✅ CSV文件已创建: \(pathString)")
            print("📊 导出 \(expenses.count) 条记录")

            // 获取临时目录路径字符串用于日志输出
            let tempDirString: String
            if #available(iOS 16.0, *) {
                tempDirString = tempDir.path()
            } else {
                tempDirString = tempDir.path
            }
            print("📁 临时目录: \(tempDirString)")

            // 验证文件确实存在 (使用URL对象的path属性,这是文件系统实际路径)
            if FileManager.default.fileExists(atPath: path.path) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: path.path)[.size] as? Int64 ?? 0
                print("✅ 文件验证成功,大小: \(fileSize) bytes")
                return path
            } else {
                print("❌ 文件创建失败,文件不存在")
                return nil
            }
        } catch {
            print("❌ CSV导出失败: \(error.localizedDescription)")
            print("❌ 错误详情: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        // 创建一个透明的容器视图控制器
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 只在第一次或者items改变时显示分享界面
        guard context.coordinator.shouldPresent else { return }
        context.coordinator.shouldPresent = false

        print("📋 准备创建 UIActivityViewController")

        // 创建分享控制器
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // 设置完成回调
        activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 分享出错: \(error.localizedDescription)")
                } else if completed {
                    print("✅ 分享成功: \(activityType?.rawValue ?? "unknown")")
                } else {
                    print("⚠️ 用户取消了分享")
                }
                onDismiss?()
            }
        }

        // 在iPad上配置popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = uiViewController.view
            popover.sourceRect = CGRect(
                x: uiViewController.view.bounds.midX,
                y: uiViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        // 在下一个运行循环显示
        DispatchQueue.main.async {
            print("📋 显示 UIActivityViewController")
            uiViewController.present(activityVC, animated: true) {
                print("✅ 分享界面已完全显示")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var shouldPresent = true
    }
}

