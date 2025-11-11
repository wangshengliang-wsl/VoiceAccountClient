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
    @ObservedObject private var categoryManager = CategoryManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedBarIndex: Int? = nil
    @State private var selectedBarLabel: String? = nil
    @State private var selectedCategoryName: String? = nil
    @State private var hiddenCategories: Set<String> = []
    @State private var hasInitializedSelection = false
    
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
        // 默认显示当前时间段的数据
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .month:
            let monthExpenses = expenses.filter {
                calendar.isDate($0.date, equalTo: now, toGranularity: .month)
            }
            return monthExpenses.reduce(0) { $0 + $1.amount }

        case .quarter:
            // 获取当前季度的起止日期
            let currentMonth = calendar.component(.month, from: now)
            let quarterStartMonth = ((currentMonth - 1) / 3) * 3 + 1
            let startComponents = DateComponents(year: calendar.component(.year, from: now), month: quarterStartMonth)
            if let startOfQuarter = calendar.date(from: startComponents),
               let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter) {
                let quarterExpenses = expenses.filter { expense in
                    expense.date >= startOfQuarter && expense.date <= endOfQuarter
                }
                return quarterExpenses.reduce(0) { $0 + $1.amount }
            }
            return 0

        case .year:
            let yearExpenses = expenses.filter {
                calendar.isDate($0.date, equalTo: now, toGranularity: .year)
            }
            return yearExpenses.reduce(0) { $0 + $1.amount }
        }
    }

    // 根据选中的柱子计算日均支出
    var displayDailyAverage: Double {
        guard let index = selectedBarIndex else { return 0 }
        let trendData = getTrendData()
        guard index < trendData.count else { return 0 }

        let amount = trendData[index].amount
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .month:
            // 月度：使用选中月份的实际天数
            let currentYear = calendar.component(.year, from: now)
            let selectedMonth = index + 1  // 月视图：索引0-11对应1-12月
            let dateComponents = DateComponents(calendar: calendar, year: currentYear, month: selectedMonth)
            if let monthDate = calendar.date(from: dateComponents) {
                let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30
                return amount / Double(daysInMonth)
            }
            return amount / 30.0

        case .quarter:
            // 季度：数组是reversed的，索引0-3对应最早到最近的季度
            // 计算该季度的实际天数
            let quarterOffset = 3 - index  // 将索引转换为偏移量
            if let date = calendar.date(byAdding: .month, value: -quarterOffset * 3, to: now),
               let startOfQuarter = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
               let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter) {
                let days = calendar.dateComponents([.day], from: startOfQuarter, to: endOfQuarter).day ?? 90
                return amount / Double(days + 1)  // +1因为包含结束日
            }
            return amount / 90.0

        case .year:
            // 年度：数组是reversed的，索引0-4对应最早到最近的年份
            let yearOffset = 4 - index  // 将索引转换为偏移量
            if let date = calendar.date(byAdding: .year, value: -yearOffset, to: now) {
                let daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
                return amount / Double(daysInYear)
            }
            return amount / 365.0
        }
    }
    
    // 根据时间段返回总支出的标题
    var totalLabel: String {
        guard let index = selectedBarIndex else {
            switch selectedPeriod {
            case .month:
                return "月支出"
            case .quarter:
                return "季度支出"
            case .year:
                return "年支出"
            }
        }

        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .month:
            let selectedMonth = index + 1
            return "\(selectedMonth)月支出"

        case .quarter:
            let quarterOffset = 3 - index
            if let date = calendar.date(byAdding: .month, value: -quarterOffset * 3, to: now) {
                let quarter = (calendar.component(.month, from: date) - 1) / 3 + 1
                let year = calendar.component(.year, from: date)
                return "\(year)年Q\(quarter)支出"
            }
            return "季度支出"

        case .year:
            let yearOffset = 4 - index
            if let date = calendar.date(byAdding: .year, value: -yearOffset, to: now) {
                let year = calendar.component(.year, from: date)
                return "\(year)年支出"
            }
            return "年支出"
        }
    }

    // 计算总支出相比上一时间段的变化百分比
    var totalChangePercentage: (value: Double, isIncrease: Bool, isFlat: Bool)? {
        let trendData = getTrendData()

        // 确定当前选中的柱子
        let currentIndex: Int
        let currentTotal: Double

        if let index = selectedBarIndex, index < trendData.count {
            // 如果选中了柱子,使用选中柱子的数据
            currentIndex = index
            currentTotal = trendData[index].amount
        } else {
            // 未选中时返回nil,不显示趋势
            return nil
        }

        // 获取上一期的数据
        let previousIndex = currentIndex - 1
        if previousIndex < 0 || previousIndex >= trendData.count {
            return nil
        }

        let previousTotal = trendData[previousIndex].amount

        // 如果都是0,显示持平
        if currentTotal == 0 && previousTotal == 0 {
            return (0, false, true)
        }

        // 如果上一期为0但当前期有值,显示上升100%
        if previousTotal == 0 && currentTotal > 0 {
            return (100.0, true, false)
        }

        // 如果当前期为0但上一期有值,显示下降100%
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

    // 计算日均支出相比上一时间段的变化百分比
    var dailyAverageChangePercentage: (value: Double, isIncrease: Bool, isFlat: Bool)? {
        let calendar = Calendar.current
        let now = Date()
        let trendData = getTrendData()

        // 确定当前选中的柱子
        guard let currentIndex = selectedBarIndex, currentIndex < trendData.count else {
            return nil
        }

        let currentAmount = trendData[currentIndex].amount
        let currentAverage: Double

        switch selectedPeriod {
        case .month:
            let currentYear = calendar.component(.year, from: now)
            let selectedMonth = currentIndex + 1
            let dateComponents = DateComponents(calendar: calendar, year: currentYear, month: selectedMonth)
            if let monthDate = calendar.date(from: dateComponents) {
                let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30
                currentAverage = currentAmount / Double(daysInMonth)
            } else {
                currentAverage = currentAmount / 30.0
            }

        case .quarter:
            let quarterOffset = 3 - currentIndex
            if let date = calendar.date(byAdding: .month, value: -quarterOffset * 3, to: now),
               let startOfQuarter = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
               let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter) {
                let days = calendar.dateComponents([.day], from: startOfQuarter, to: endOfQuarter).day ?? 90
                currentAverage = currentAmount / Double(days + 1)
            } else {
                currentAverage = currentAmount / 90.0
            }

        case .year:
            let yearOffset = 4 - currentIndex
            if let date = calendar.date(byAdding: .year, value: -yearOffset, to: now) {
                let daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
                currentAverage = currentAmount / Double(daysInYear)
            } else {
                currentAverage = currentAmount / 365.0
            }
        }

        // 获取上一期的数据
        let previousIndex = currentIndex - 1
        if previousIndex < 0 || previousIndex >= trendData.count {
            return nil
        }

        let previousAmount = trendData[previousIndex].amount
        let previousAverage: Double

        switch selectedPeriod {
        case .month:
            let currentYear = calendar.component(.year, from: now)
            let selectedMonth = previousIndex + 1
            let dateComponents = DateComponents(calendar: calendar, year: currentYear, month: selectedMonth)
            if let monthDate = calendar.date(from: dateComponents) {
                let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30
                previousAverage = previousAmount / Double(daysInMonth)
            } else {
                previousAverage = previousAmount / 30.0
            }

        case .quarter:
            let quarterOffset = 3 - previousIndex
            if let date = calendar.date(byAdding: .month, value: -quarterOffset * 3, to: now),
               let startOfQuarter = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
               let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter) {
                let days = calendar.dateComponents([.day], from: startOfQuarter, to: endOfQuarter).day ?? 90
                previousAverage = previousAmount / Double(days + 1)
            } else {
                previousAverage = previousAmount / 90.0
            }

        case .year:
            let yearOffset = 4 - previousIndex
            if let date = calendar.date(byAdding: .year, value: -yearOffset, to: now) {
                let daysInYear = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
                previousAverage = previousAmount / Double(daysInYear)
            } else {
                previousAverage = previousAmount / 365.0
            }
        }

        // 如果都是0,显示持平
        if currentAverage == 0 && previousAverage == 0 {
            return (0, false, true)
        }

        // 如果上一期为0但当前期有值,显示上升100%
        if previousAverage == 0 && currentAverage > 0 {
            return (100.0, true, false)
        }

        // 如果当前期为0但上一期有值,显示下降100%
        if currentAverage == 0 && previousAverage > 0 {
            return (100.0, false, false)
        }

        let change = ((currentAverage - previousAverage) / previousAverage) * 100

        // 判断是否持平 (变化小于0.5%)
        if abs(change) < 0.5 {
            return (0, false, true)
        }

        return (abs(change), change > 0, false)
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
            // 默认选中当前时间段
            if !hasInitializedSelection {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    setDefaultSelection()
                }
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
        .onChange(of: selectedPeriod) { oldValue, newValue in
            // 使用平滑的淡出-淡入动画,而不是柱子的缩放动画
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedBarIndex = nil
                selectedBarLabel = nil
            }

            // 延迟选中当前期,让数据有时间更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                setDefaultSelection()
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
                    .contentTransition(.numericText())
                Text(totalLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let change = totalChangePercentage {
                    HStack(spacing: 4) {
                        // 持平时不显示比较文案前缀
                        if !change.isFlat {
                            Text(getPeriodComparisonPrefix())
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
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10)

            // Daily Average
            VStack(spacing: 8) {
                Text("\(currencyManager.currentCurrency.symbol) \(displayDailyAverage, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .contentTransition(.numericText())
                Text("日均支出")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let change = dailyAverageChangePercentage {
                    HStack(spacing: 4) {
                        // 持平时不显示比较文案前缀
                        if !change.isFlat {
                            Text(getPeriodComparisonPrefix())
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
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedBarIndex)
        .animation(.easeInOut(duration: 0.3), value: displayTotal)
        .animation(.easeInOut(duration: 0.3), value: displayDailyAverage)
        .padding(.horizontal)
    }
    
    private var trendChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("支出趋势")
                                    .font(.headline)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "hand.tap.fill")
                                        .font(.caption)
                                    Text("点击切换柱子")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            
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
                                                y: .value("金额", item.amount)
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

                                        if adjustedX >= 0 && adjustedX <= chartWidth {
                                            let barWidth = chartWidth / CGFloat(data.count)
                                            let tappedIndex = Int(adjustedX / barWidth)

                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                if tappedIndex >= 0 && tappedIndex < data.count {
                                                    // 单选模式：只切换到新柱子,不取消选中
                                                    if selectedBarIndex != tappedIndex {
                                                        selectedBarIndex = tappedIndex
                                                        selectedBarLabel = data[tappedIndex].label
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    // 使用单一的平滑动画
                                    .animation(.easeInOut(duration: 0.3), value: selectedBarIndex)
                                    .animation(.easeInOut(duration: 0.3), value: selectedPeriod)
                                }
                                .frame(height: 200)
                                // 添加ID来确保切换时间段时视图重新创建
                                .id(selectedPeriod)
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

    // 获取时间段比较的文案前缀
    private func getPeriodComparisonPrefix() -> String {
        switch selectedPeriod {
        case .month:
            return "较上月"
        case .quarter:
            return "较上季"
        case .year:
            return "较上年"
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

    // 设置默认选中当前月/季/年
    private func setDefaultSelection() {
        hasInitializedSelection = true
        let calendar = Calendar.current
        let now = Date()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            switch selectedPeriod {
            case .month:
                // 选中当前月份（1-12）
                let currentMonth = calendar.component(.month, from: now)
                selectedBarIndex = currentMonth - 1  // 转换为0-based索引
                selectedBarLabel = "\(currentMonth)月"

            case .quarter:
                // 选中当前季度（最近4个季度中的最后一个，即当前季度）
                selectedBarIndex = 3  // 数组reversed后,当前季度在索引3
                let currentMonth = calendar.component(.month, from: now)
                let quarter = (currentMonth - 1) / 3 + 1
                selectedBarLabel = "Q\(quarter)"

            case .year:
                // 选中当前年份（最近5年中的最后一个，即今年）
                selectedBarIndex = 4  // 数组reversed后,今年在索引4
                let currentYear = calendar.component(.year, from: now)
                selectedBarLabel = "\(currentYear)"
            }
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: Expense.self, inMemory: true)
        .environmentObject(ThemeManager.shared)
}

