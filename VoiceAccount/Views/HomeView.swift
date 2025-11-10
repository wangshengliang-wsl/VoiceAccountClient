//
//  HomeView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingManualInput = false
    @State private var showingVoiceInput = false
    @State private var uploadStatus: String = ""
    @State private var isUploading = false
    
    var todayExpenses: [Expense] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return expenses.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    var monthlyTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        let monthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return monthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ZStack {
            // Themed Background
            ThemedBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("记账")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Monthly Summary Card
                        VStack(spacing: 8) {
                            Text("本月支出")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                Text("\(currencyManager.currentCurrency.symbol) \(monthlyTotal, specifier: "%.2f")")
                                .font(.system(size: 34, weight: .bold))
                            Text("较上月 +12.5%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            // Voice Input Button
                            Button(action: {
                                showingVoiceInput = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 30))
                                    Text("语音输入")
                                        .fontWeight(.semibold)
                                    Text("点击开始录音")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.3), radius: 10)
                            }
                            
                            // Manual Input Button
                            Button(action: {
                                showingManualInput = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 30))
                                    Text("手动输入")
                                        .fontWeight(.semibold)
                                    Text("点击添加记录")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.94, green: 0.58, blue: 0.98), Color(red: 0.96, green: 0.34, blue: 0.42)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: Color(red: 0.96, green: 0.34, blue: 0.42).opacity(0.3), radius: 10)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Today's Records
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日记录")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            if todayExpenses.isEmpty {
                                Text("今天还没有记录")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(todayExpenses) { expense in
                                    ExpenseRowView(expense: expense, currencyManager: currencyManager)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
            }
        }
        .sheet(isPresented: $showingManualInput) {
            ManualInputView()
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputView(audioRecorder: audioRecorder, isUploading: $isUploading, uploadStatus: $uploadStatus)
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    @ObservedObject var currencyManager: CurrencyManager
    @ObservedObject private var categoryManager = CategoryManager.shared
    
    var categoryItem: CategoryItem? {
        categoryManager.allCategories.first { $0.name == expense.category }
    }
    
    var displayIcon: String {
        categoryItem?.iconName ?? expense.expenseCategory.icon
    }
    
    var displayColor: Color {
        categoryItem?.color ?? expense.expenseCategory.color
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(displayColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: displayIcon)
                    .foregroundColor(displayColor)
            }
            
            // Title and Time
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .fontWeight(.medium)
                Text(expense.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount and Category
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currencyManager.currentCurrency.symbol) \(expense.amount, specifier: "%.2f")")
                    .fontWeight(.semibold)
                Text(expense.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct ManualInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var categoryManager = CategoryManager.shared
    
    @State private var amount = ""
    @State private var title = ""
    @State private var selectedCategoryName = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主题背景
                ThemedBackgroundView()
                
                VStack(spacing: 20) {
                    // Amount Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("金额")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Title Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标题")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("例如：午餐、咖啡", text: $title)
                            .font(.system(size: 16))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分类")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if categoryManager.allCategories.isEmpty {
                            Text("暂无分类，请先在设置中添加")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Picker("分类", selection: $selectedCategoryName) {
                                ForEach(categoryManager.allCategories) { category in
                                    HStack {
                                        Image(systemName: category.iconName)
                                        Text(category.name)
                                    }
                                    .tag(category.name)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("时间")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("添加支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveExpense()
                    }
                    .disabled(amount.isEmpty || title.isEmpty || selectedCategoryName.isEmpty)
                }
            }
            .onAppear {
                // 设置默认选中第一个分类
                if selectedCategoryName.isEmpty, let firstCategory = categoryManager.allCategories.first {
                    selectedCategoryName = firstCategory.name
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount), 
              !title.isEmpty,
              !selectedCategoryName.isEmpty else { return }
        
        let expense = Expense(
            amount: amountValue,
            title: title,
            categoryName: selectedCategoryName,
            date: date
        )
        modelContext.insert(expense)
        dismiss()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Expense.self, inMemory: true)
        .environmentObject(ThemeManager.shared)
}

