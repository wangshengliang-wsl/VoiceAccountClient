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
    @State private var isEditMode = false
    @State private var selectedExpenses: Set<UUID> = []
    
    var todayExpenses: [Expense] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return expenses.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }

    // 计算今日总支出
    var todayTotal: Double {
        return todayExpenses.reduce(0) { $0 + $1.amount }
    }

    // 计算昨日总支出
    var yesterdayTotal: Double {
        let calendar = Calendar.current
        let today = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return 0
        }
        let yesterdayExpenses = expenses.filter {
            calendar.isDate($0.date, inSameDayAs: yesterday)
        }
        return yesterdayExpenses.reduce(0) { $0 + $1.amount }
    }

    // 计算较昨天的变化百分比
    var dailyChangePercentage: (value: Double, isIncrease: Bool, isFlat: Bool)? {
        let currentTotal = todayTotal
        let previousTotal = yesterdayTotal

        // 如果都是0,不显示趋势
        if currentTotal == 0 && previousTotal == 0 {
            return nil
        }

        // 如果昨天为0但今天有值,显示上升100%
        if previousTotal == 0 && currentTotal > 0 {
            return (100.0, true, false)
        }

        // 如果今天为0但昨天有值,显示下降100%
        if currentTotal == 0 && previousTotal > 0 {
            return (100.0, false, false)
        }

        let change = ((currentTotal - previousTotal) / previousTotal) * 100

        // 判断是否持平 (变化小于0.5%)
        if abs(change) < 0.5 {
            return (0, false, true)
        }

        return (abs(change), change > 0, false)
    }
    
    var monthlyTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        let monthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return monthExpenses.reduce(0) { $0 + $1.amount }
    }

    // 计算上月总支出
    var lastMonthTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
            return 0
        }
        let lastMonthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: lastMonth, toGranularity: .month)
        }
        return lastMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    // 计算较上月的变化百分比
    var monthlyChangePercentage: (value: Double, isIncrease: Bool, isFlat: Bool)? {
        let currentTotal = monthlyTotal
        let previousTotal = lastMonthTotal

        // 如果都是0,显示持平
        if currentTotal == 0 && previousTotal == 0 {
            return nil  // 不显示任何趋势
        }

        // 如果上月为0但本月有值,显示上升100%
        if previousTotal == 0 && currentTotal > 0 {
            return (100.0, true, false)
        }

        // 如果本月为0但上月有值,显示下降100%
        if currentTotal == 0 && previousTotal > 0 {
            return (100.0, false, false)
        }

        let change = ((currentTotal - previousTotal) / previousTotal) * 100

        // 判断是否持平 (变化小于0.5%)
        if abs(change) < 0.5 {
            return (0, false, true)
        }

        return (abs(change), change > 0, false)
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
                    if !todayExpenses.isEmpty {
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Daily Summary Card
                        VStack(spacing: 8) {
                            Text("今日支出")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                Text("\(currencyManager.currentCurrency.symbol) \(todayTotal, specifier: "%.2f")")
                                .font(.system(size: 34, weight: .bold))
                            // 较昨天变化百分比
                            if let change = dailyChangePercentage {
                                HStack(spacing: 4) {
                                    // 持平时不显示"较昨天"文案
                                    if !change.isFlat {
                                        Text("较昨天")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if change.isFlat {
                                        Image(systemName: "equal")
                                            .font(.caption)
                                        Text("持平")
                                            .font(.caption)
                                    } else {
                                        Image(systemName: change.isIncrease ? "arrow.up" : "arrow.down")
                                            .font(.caption)
                                        Text("\(change.value, specifier: "%.1f")%")
                                            .font(.caption)
                                    }
                                }
                                .foregroundColor(change.isFlat ? .gray : (change.isIncrease ? .red : .green))
                            }
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
                            HStack {
                                Text("今日记录")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                                if isEditMode && !selectedExpenses.isEmpty {
                                    Button(role: .destructive, action: {
                                        deleteSelectedExpenses()
                                    }) {
                                        Label("删除 \(selectedExpenses.count) 项", systemImage: "trash")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.horizontal)

                            if todayExpenses.isEmpty {
                                Text("今天还没有记录")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(todayExpenses) { expense in
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
            for expense in todayExpenses where selectedExpenses.contains(expense.id) {
                modelContext.delete(expense)
            }
            selectedExpenses.removeAll()
            isEditMode = false
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    @ObservedObject var currencyManager: CurrencyManager
    @ObservedObject private var categoryManager = CategoryManager.shared
    var isEditMode: Bool = false
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var showingEditView = false

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
            // Selection Circle in Edit Mode
            if isEditMode {
                Button(action: {
                    onSelect?()
                }) {
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

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
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditMode {
                showingEditView = true
            }
        }
        .sheet(isPresented: $showingEditView) {
            ExpenseEditView(expense: expense)
                .environmentObject(ThemeManager.shared)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isEditMode, let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .contextMenu {
            if !isEditMode, let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}

struct ManualInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var categoryManager = CategoryManager.shared
    
    @State private var amount = ""
    @State private var title = ""
    @State private var selectedCategoryName = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主题背景
                ThemedBackgroundView()

                ScrollView {
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
                            // 使用 LazyVGrid 平铺展示分类
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                                ForEach(categoryManager.allCategories) { category in
                                    Button(action: {
                                        selectedCategoryName = category.name
                                    }) {
                                        VStack(spacing: 6) {
                                            // 圆形图标背景
                                            ZStack {
                                                Circle()
                                                    .fill(selectedCategoryName == category.name ? category.color : category.color.opacity(0.15))
                                                    .frame(width: 50, height: 50)
                                                Image(systemName: category.iconName)
                                                    .font(.system(size: 24))
                                                    .foregroundColor(selectedCategoryName == category.name ? .white : category.color)
                                            }
                                            Text(category.name)
                                                .font(.caption)
                                                .fontWeight(selectedCategoryName == category.name ? .semibold : .regular)
                                                .foregroundColor(.primary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
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
                .dismissKeyboardOnTap()
            }
            .dismissKeyboardOnScroll()
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

