import SwiftUI
import SwiftData

struct ExpenseEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var categoryManager = CategoryManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared

    let expense: Expense

    @State private var amount: String
    @State private var title: String
    @State private var selectedCategory: String
    @State private var date: Date
    @State private var notes: String

    @State private var showingSaveAlert = false
    @State private var saveMessage = ""

    init(expense: Expense) {
        self.expense = expense
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _title = State(initialValue: expense.title)
        _selectedCategory = State(initialValue: expense.category)
        _date = State(initialValue: expense.date)
        _notes = State(initialValue: expense.notes ?? "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                ThemedBackgroundView()

                Form {
                    Section(header: Text("基本信息")) {
                        // 标题
                        HStack {
                            Text("标题")
                                .frame(width: 60, alignment: .leading)
                            TextField("输入描述", text: $title)
                        }

                        // 金额
                        HStack {
                            Text("金额")
                                .frame(width: 60, alignment: .leading)
                            HStack(spacing: 4) {
                                Text(currencyManager.currentCurrency.symbol)
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        // 日期
                        DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    }
                    .listRowBackground(Color.clear)

                    Section(header: Text("分类")) {
                        // 使用 LazyVGrid 平铺展示分类
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                            ForEach(categoryManager.allCategories, id: \.name) { category in
                                Button(action: {
                                    selectedCategory = category.name
                                }) {
                                    VStack(spacing: 6) {
                                        // 圆形图标背景
                                        ZStack {
                                            Circle()
                                                .fill(selectedCategory == category.name ? category.color : category.color.opacity(0.15))
                                                .frame(width: 50, height: 50)
                                            Image(systemName: category.iconName)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedCategory == category.name ? .white : category.color)
                                        }
                                        Text(category.name)
                                            .font(.caption)
                                            .fontWeight(selectedCategory == category.name ? .semibold : .regular)
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)

                    Section(header: Text("备注(可选)")) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .dismissKeyboardOnScroll()
                .dismissKeyboardOnTap()
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("保存结果", isPresented: $showingSaveAlert) {
                Button("确定", role: .cancel) {
                    if saveMessage.contains("成功") {
                        dismiss()
                    }
                }
            } message: {
                Text(saveMessage)
            }
        }
    }

    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            saveMessage = "请输入有效的金额"
            showingSaveAlert = true
            return
        }

        guard !title.isEmpty else {
            saveMessage = "请输入标题"
            showingSaveAlert = true
            return
        }

        // 更新expense对象
        expense.amount = amountValue
        expense.title = title
        expense.category = selectedCategory
        expense.date = date
        expense.notes = notes.isEmpty ? nil : notes

        do {
            try modelContext.save()
            saveMessage = "保存成功"
            showingSaveAlert = true
        } catch {
            saveMessage = "保存失败: \(error.localizedDescription)"
            showingSaveAlert = true
        }
    }
}
