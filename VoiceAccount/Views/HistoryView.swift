//
//  HistoryView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var searchText = ""
    
    var filteredExpenses: [Expense] {
        if searchText.isEmpty {
            return expenses
        } else {
            return expenses.filter { expense in
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.expenseCategory.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var groupedExpenses: [(date: Date, expenses: [Expense], total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        return grouped.map { date, expensesList in
            let total = expensesList.reduce(0) { $0 + $1.amount }
            return (date, expensesList.sorted { $0.date > $1.date }, total)
        }
        .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            // Themed Background
            ThemedBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("历史")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索记录...", text: $searchText)
                    }
                    .padding(12)
                    .background(.white.opacity(0.5))
                    .cornerRadius(12)
                    
                    Button(action: {}) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // History List
                if groupedExpenses.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("暂无记录")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedExpenses, id: \.date) { group in
                                Section {
                                    VStack(spacing: 12) {
                                        ForEach(group.expenses) { expense in
                                            ExpenseRowView(expense: expense, currencyManager: currencyManager)
                                                .contextMenu {
                                                    Button(role: .destructive) {
                                                        deleteExpense(expense)
                                                    } label: {
                                                        Label("删除", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                } header: {
                                    DateHeaderView(
                                        date: group.date,
                                        total: group.total,
                                        count: group.expenses.count
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
        }
    }
}

struct DateHeaderView: View {
    let date: Date
    let total: Double
    let count: Int
    
    var dateText: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
    
    var weekdayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateText)
                    .font(.headline)
                Text(weekdayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(CurrencyManager.shared.currentCurrency.symbol) \(total, specifier: "%.2f")")
                    .font(.headline)
                Text("\(count)笔")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(0)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: Expense.self, inMemory: true)
        .environmentObject(ThemeManager.shared)
}

