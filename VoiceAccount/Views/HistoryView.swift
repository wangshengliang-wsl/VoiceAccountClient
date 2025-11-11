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
    @State private var isEditMode = false
    @State private var selectedExpenses: Set<UUID> = []
    
    var filteredExpenses: [Expense] {
        if searchText.isEmpty {
            return expenses
        } else {
            return expenses.filter { expense in
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.category.localizedCaseInsensitiveContains(searchText)
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
                    if !filteredExpenses.isEmpty {
                        Button(action: {
                            withAnimation {
                                isEditMode.toggle()
                                selectedExpenses.removeAll()
                            }
                        }) {
                            Text(isEditMode ? "取消" : "批量删除")
                                .fontWeight(.medium)
                                .foregroundColor(isEditMode ? .primary : .red)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Search Bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索记录...", text: $searchText)
                    }
                    .padding(12)
                    .background(.white.opacity(0.5))
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity)

                    if isEditMode && !selectedExpenses.isEmpty {
                        Button(role: .destructive, action: {
                            deleteSelectedExpenses()
                        }) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(.red)
                                .cornerRadius(12)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditMode)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedExpenses.count)
                
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
                    .dismissKeyboardOnTap()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedExpenses, id: \.date) { group in
                                Section {
                                    VStack(spacing: 12) {
                                        ForEach(group.expenses) { expense in
                                            ExpenseRowView(
                                                expense: expense,
                                                currencyManager: currencyManager,
                                                isEditMode: isEditMode,
                                                isSelected: selectedExpenses.contains(expense.id),
                                                onSelect: {
                                                    toggleSelection(expense)
                                                },
                                                onDelete: {
                                                    deleteExpense(expense)
                                                }
                                            )
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
                    .dismissKeyboardOnScroll()
                }
            }
        }
    }

    private func toggleSelection(_ expense: Expense) {
        if selectedExpenses.contains(expense.id) {
            selectedExpenses.remove(expense.id)
        } else {
            selectedExpenses.insert(expense.id)
        }
    }

    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
        }
    }

    private func deleteSelectedExpenses() {
        withAnimation {
            for expense in filteredExpenses where selectedExpenses.contains(expense.id) {
                modelContext.delete(expense)
            }
            selectedExpenses.removeAll()
            isEditMode = false
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

