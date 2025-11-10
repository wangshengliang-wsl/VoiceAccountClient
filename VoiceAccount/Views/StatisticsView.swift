//
//  StatisticsView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI
import SwiftData
import Charts
import Combine

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @StateObject private var categoryManager = CategoryManager()
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var selectedPeriod: TimePeriod = .month
    @State private var animateChart = false
    @State private var selectedBarIndex: Int? = nil
    @State private var selectedBarLabel: String? = nil
    @State private var selectedCategoryName: String? = nil
    @State private var hiddenCategories: Set<String> = []
    
    enum TimePeriod: String, CaseIterable {
        case month = "月"
        case quarter = "季度"
        case year = "年"
    }
    
    // 根据选中的柱子计算总支出
    var displayTotal: Double {
        let trendData = getTrendData()
        if let index = selectedBarIndex, index < trendData.count {
            return trendData[index].amount
        }
        // 默认显示当前月的数据
        let calendar = Calendar.current
        let now = Date()
        let monthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return monthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 根据选中的柱子计算日均支出
    var displayDailyAverage: Double {
        let trendData = getTrendData()
        if let index = selectedBarIndex, index < trendData.count {
            let amount = trendData[index].amount
            switch selectedPeriod {
            case .month:
                // 月度：除以30天
                return amount / 30.0
            case .quarter:
                // 季度：除以90天
                return amount / 90.0
            case .year:
                // 年度：除以365天
                return amount / 365.0
            }
        }
        // 默认显示当前月的日均
        let calendar = Calendar.current
        let now = Date()
        let monthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        let days = calendar.component(.day, from: now)
        return days > 0 ? monthExpenses.reduce(0) { $0 + $1.amount } / Double(days) : 0
    }
    
    // 根据时间段返回总支出的标题
    var totalLabel: String {
        switch selectedPeriod {
        case .month:
            return "本月支出"
        case .quarter:
            return "本季支出"
        case .year:
            return "本年支出"
        }
    }
    
    var categoryTotals: [(name: String, total: Double, percentage: Double, iconName: String, color: Color)] {
        let calendar = Calendar.current
        let now = Date()
        
        // 根据是否选中柱子来决定显示哪个时间段的数据
        let filteredExpenses: [Expense]
        if let selectedIndex = selectedBarIndex {
            // 如果选中了柱子，只显示该时间段的数据
            let trendData = getTrendData()
            if selectedIndex < trendData.count {
                switch selectedPeriod {
                case .month:
                    // 月度：显示选中月份的数据
                    let currentYear = calendar.component(.year, from: now)
                    let selectedMonth = selectedIndex + 1
                    let dateComponents = DateComponents(calendar: calendar, year: currentYear, month: selectedMonth)
                    if let monthDate = calendar.date(from: dateComponents) {
                        filteredExpenses = expenses.filter {
                            calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month)
                        }
                    } else {
                        filteredExpenses = []
                    }
                    
                case .quarter:
                    // 季度：显示选中季度的数据
                    let quarterOffset = 3 - selectedIndex  // 反转索引，因为getTrendData是reversed的
                    if let date = calendar.date(byAdding: .month, value: -quarterOffset * 3, to: now) {
                        let startOfQuarter = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                        let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter)!
                        filteredExpenses = expenses.filter { expense in
                            expense.date >= startOfQuarter && expense.date <= endOfQuarter
                        }
                    } else {
                        filteredExpenses = []
                    }
                    
                case .year:
                    // 年度：显示选中年份的数据
                    let yearOffset = 4 - selectedIndex  // 反转索引，因为getTrendData是reversed的
                    if let date = calendar.date(byAdding: .year, value: -yearOffset, to: now) {
                        filteredExpenses = expenses.filter {
                            calendar.isDate($0.date, equalTo: date, toGranularity: .year)
                        }
                    } else {
                        filteredExpenses = []
                    }
                }
            } else {
                filteredExpenses = []
            }
        } else {
            // 未选中柱子时，显示所有支出的分类分布
            filteredExpenses = expenses
        }
        
        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        
        // 使用真实的分类数据
        var categoryData: [(name: String, total: Double, percentage: Double, iconName: String, color: Color)] = []
        
        for category in categoryManager.allCategories {
            let categoryTotal = filteredExpenses
                .filter { $0.category == category.name }
                .reduce(0) { $0 + $1.amount }
            let percentage = total > 0 ? (categoryTotal / total) * 100 : 0
            
            if categoryTotal > 0 {
                categoryData.append((category.name, categoryTotal, percentage, category.iconName, category.color))
            }
        }
        
        return categoryData.sorted { $0.total > $1.total }
    }
    
    var body: some View {
        ZStack {
            ThemedBackgroundView()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    contentView
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text("统计")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            timePeriodSelector
            summaryCards
            trendChartView
            categoryDistributionView
            categoryBreakdownView
        }
        .padding(.vertical)
    }
    
    private var timePeriodSelector: some View {
        Picker("时间段", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: selectedPeriod) { _ in
            selectedBarIndex = nil
            selectedBarLabel = nil
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateChart.toggle()
            }
        }
    }
    
    private var summaryCards: some View {
                        HStack(spacing: 12) {
                            // Total
                            VStack(spacing: 8) {
                                Text("\(currencyManager.currentCurrency.symbol) \(Int(displayTotal))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .id("total-\(selectedBarIndex?.description ?? "none")")
                                Text(totalLabel)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if selectedBarIndex != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                        Text("已选中")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.blue)
                                    .transition(.scale.combined(with: .opacity))
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.down")
                                            .font(.caption)
                                        Text("8.5%")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.green)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: selectedBarIndex)
                            
                            // Daily Average
                            VStack(spacing: 8) {
                                Text("\(currencyManager.currentCurrency.symbol) \(Int(displayDailyAverage))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .id("average-\(selectedBarIndex?.description ?? "none")")
                                Text("日均支出")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if selectedBarIndex != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.caption)
                                        Text("平均值")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.blue)
                                    .transition(.scale.combined(with: .opacity))
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up")
                                            .font(.caption)
                                        Text("12.3%")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.red)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: selectedBarIndex)
        }
        .padding(.horizontal)
    }
    
    private var trendChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("支出趋势")
                                    .font(.headline)
                                Spacer()
                                if selectedBarIndex != nil {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                            selectedBarIndex = nil
                                            selectedBarLabel = nil
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "xmark.circle.fill")
                                            Text("清除选择")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(20)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "hand.tap.fill")
                                            .font(.caption)
                                        Text("点击柱子查看详情")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedBarIndex)
                            
                            if #available(iOS 16.0, *) {
                                let data = getTrendData()
                                let maxAmount = data.map { $0.amount }.max() ?? 100
                                // 计算是否显示数字的阈值（显示金额大于最大值20%的柱子）
                                let displayThreshold = maxAmount * 0.2
                                
                                GeometryReader { geometry in
                                    Chart {
                                        ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                                            BarMark(
                                                x: .value("时间", item.label),
                                                y: .value("金额", animateChart ? item.amount : 0)
                                            )
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.pink.opacity(0.8), .orange.opacity(0.8)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .opacity(selectedBarIndex == nil || selectedBarIndex == index ? 1.0 : 0.3)
                                            .cornerRadius(8)
                                            .annotation(position: .top, alignment: .center, spacing: 4) {
                                                // 智能显示数字：选中的柱子或金额较大的柱子才显示
                                                let shouldShowLabel = selectedBarIndex == index || 
                                                                     (selectedBarIndex == nil && item.amount >= displayThreshold)
                                                if item.amount > 0 && shouldShowLabel {
                                                    Text("\(Int(item.amount))")
                                                        .font(.system(size: 10, weight: selectedBarIndex == index ? .bold : .semibold))
                                                        .foregroundColor(selectedBarIndex == index ? .orange : .gray)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .fill(Color.white.opacity(0.9))
                                                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                                        )
                                                        .transition(.scale.combined(with: .opacity))
                                                }
                                            }
                                        }
                                    }
                                    .chartYScale(domain: 0...(maxAmount * 1.15))
                                    .chartYAxis {
                                        AxisMarks(position: .leading) { value in
                                            AxisValueLabel {
                                                if let amount = value.as(Double.self) {
                                                    Text("\(Int(amount))")
                                                        .font(.caption2)
                                                }
                                            }
                                            AxisGridLine()
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { location in
                                        // 计算点击位置对应的柱子索引
                                        // 考虑Y轴标签的宽度（约40pt）和图表边距
                                        let yAxisWidth: CGFloat = 40
                                        let chartWidth = geometry.size.width - yAxisWidth
                                        let adjustedX = location.x - yAxisWidth
                                        
                                        print("📊 点击位置: \(location.x), 调整后: \(adjustedX), 图表宽度: \(chartWidth)")
                                        
                                        if adjustedX >= 0 && adjustedX <= chartWidth {
                                            let barWidth = chartWidth / CGFloat(data.count)
                                            let tappedIndex = Int(adjustedX / barWidth)
                                            
                                            print("📊 柱子宽度: \(barWidth), 点击索引: \(tappedIndex), 数据数量: \(data.count)")
                                            
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                                if tappedIndex >= 0 && tappedIndex < data.count {
                                                    if selectedBarIndex == tappedIndex {
                                                        // 点击已选中的柱子则取消选中
                                                        print("✅ 取消选中柱子 \(tappedIndex)")
                                                        selectedBarIndex = nil
                                                        selectedBarLabel = nil
                                                    } else {
                                                        // 选中新的柱子
                                                        print("✅ 选中柱子 \(tappedIndex): \(data[tappedIndex].label), 金额: \(data[tappedIndex].amount)")
                                                        selectedBarIndex = tappedIndex
                                                        selectedBarLabel = data[tappedIndex].label
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateChart)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedBarIndex)
                                }
                                .frame(height: 200)
                            } else {
                                Text("需要 iOS 16+ 支持图表功能")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 200)
                            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
        .padding(.horizontal)
    }
    
    private var categoryDistributionView: some View {
        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("分类分布")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chart.pie.fill")
                                    .foregroundColor(.purple)
                            }
                            
                            // 图例
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                ForEach(categoryTotals, id: \.name) { item in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            if hiddenCategories.contains(item.name) {
                                                hiddenCategories.remove(item.name)
                                            } else {
                                                hiddenCategories.insert(item.name)
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(hiddenCategories.contains(item.name) ? Color.gray.opacity(0.3) : item.color)
                                                .frame(width: 8, height: 8)
                                            Text(item.name)
                                                .font(.caption)
                                                .foregroundColor(hiddenCategories.contains(item.name) ? .secondary : .primary)
                                                .strikethrough(hiddenCategories.contains(item.name))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(hiddenCategories.contains(item.name) ? Color.gray.opacity(0.1) : item.color.opacity(0.15))
                                        )
                                    }
                                }
                            }
                            
                            if #available(iOS 16.0, *) {
                                let visibleCategories = categoryTotals.filter { !hiddenCategories.contains($0.name) }
                                let maxAmount = visibleCategories.map { $0.total }.max() ?? 100
                                
                                GeometryReader { geometry in
                                    Chart {
                                        ForEach(Array(visibleCategories.enumerated()), id: \.element.name) { index, item in
                                            let isSelected = selectedCategoryName == item.name
                                            let barGradient = isSelected ?
                                                LinearGradient(
                                                    colors: [item.color.opacity(1.0), item.color.opacity(0.7)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ) :
                                                LinearGradient(
                                                    colors: [item.color.opacity(0.8), item.color.opacity(0.6)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            
                                            BarMark(
                                                x: .value("分类", item.name),
                                                y: .value("金额", item.total)
                                            )
                                            .foregroundStyle(barGradient)
                                            .cornerRadius(8)
                                            .annotation(position: .top, alignment: .center) {
                                                let textWeight: Font.Weight = isSelected ? .bold : .semibold
                                                let textColor: Color = isSelected ? item.color : .gray
                                                
                                                Text("\(Int(item.total))")
                                                    .font(.caption2)
                                                    .fontWeight(textWeight)
                                                    .foregroundColor(textColor)
                                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedCategoryName)
                                            }
                                        }
                                    }
                                    .chartYScale(domain: 0...(maxAmount * 1.15))
                                    .chartYAxis {
                                        AxisMarks(position: .leading) { value in
                                            AxisValueLabel {
                                                if let amount = value.as(Double.self) {
                                                    Text("\(Int(amount))")
                                                        .font(.caption2)
                                                }
                                            }
                                            AxisGridLine()
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { location in
                                        let yAxisWidth: CGFloat = 40
                                        let chartWidth = geometry.size.width - yAxisWidth
                                        let adjustedX = location.x - yAxisWidth
                                        
                                        if adjustedX >= 0 && adjustedX <= chartWidth && !visibleCategories.isEmpty {
                                            let barWidth = chartWidth / CGFloat(visibleCategories.count)
                                            let tappedIndex = Int(adjustedX / barWidth)
                                            
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                if tappedIndex >= 0 && tappedIndex < visibleCategories.count {
                                                    let tappedCategory = visibleCategories[tappedIndex].name
                                                    if selectedCategoryName == tappedCategory {
                                                        selectedCategoryName = nil
                                                    } else {
                                                        selectedCategoryName = tappedCategory
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedCategoryName)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hiddenCategories)
                                }
                                .frame(height: 200)
                            } else {
                                Text("需要 iOS 16+ 支持图表功能")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 200)
                            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
        .padding(.horizontal)
    }
    
    private var categoryBreakdownView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类明细")
                .font(.headline)
            
            ForEach(categoryTotals.filter { !hiddenCategories.contains($0.name) }, id: \.name) { item in
                categoryBreakdownRow(item: item)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private func categoryBreakdownRow(item: (name: String, total: Double, percentage: Double, iconName: String, color: Color)) -> some View {
        HStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(item.color)
                    .frame(width: 12, height: 12)
                Text(item.name)
                    .foregroundColor(.primary)
                    .fontWeight(selectedCategoryName == item.name ? .bold : .regular)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currencyManager.currentCurrency.symbol) \(Int(item.total))")
                    .fontWeight(selectedCategoryName == item.name ? .bold : .semibold)
                    .foregroundColor(selectedCategoryName == item.name ? item.color : .primary)
                Text("\(item.percentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedCategoryName == item.name ? item.color.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if selectedCategoryName == item.name {
                    selectedCategoryName = nil
                } else {
                    selectedCategoryName = item.name
                }
            }
        }
    }
    
    private func getTrendData() -> [(label: String, amount: Double)] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .month:
            // 显示1-12月的数据（使用公历）
            let currentYear = calendar.component(.year, from: now)
            return (1...12).map { month in
                // 创建指定月份的日期
                let dateComponents = DateComponents(calendar: calendar, year: currentYear, month: month)
                guard let monthDate = calendar.date(from: dateComponents) else {
                    return ("\(month)月", 0.0)
                }
                
                let monthExpenses = expenses.filter {
                    calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month)
                }
                
                let total = monthExpenses.reduce(0) { $0 + $1.amount }
                
                return ("\(month)月", total)
            }
            
        case .quarter:
            // 最近4个季度
            return (0..<4).map { quarterOffset in
                guard let date = calendar.date(byAdding: .month, value: -quarterOffset * 3, to: now) else {
                    return ("Q\(quarterOffset + 1)", 0.0)
                }
                
                let startOfQuarter = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter)!
                
                let quarterExpenses = expenses.filter { expense in
                    expense.date >= startOfQuarter && expense.date <= endOfQuarter
                }
                
                let total = quarterExpenses.reduce(0) { $0 + $1.amount }
                let quarter = (calendar.component(.month, from: date) - 1) / 3 + 1
                
                return ("Q\(quarter)", total)
            }.reversed()
            
        case .year:
            // 最近5年
            return (0..<5).map { yearOffset in
                guard let date = calendar.date(byAdding: .year, value: -yearOffset, to: now) else {
                    return ("", 0.0)
                }
                
                let yearExpenses = expenses.filter {
                    calendar.isDate($0.date, equalTo: date, toGranularity: .year)
                }
                
                let total = yearExpenses.reduce(0) { $0 + $1.amount }
                let year = calendar.component(.year, from: date)
                
                return ("\(year)", total)
            }.reversed()
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: Expense.self, inMemory: true)
        .environmentObject(ThemeManager.shared)
}

