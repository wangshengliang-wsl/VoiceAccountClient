import SwiftUI
import SwiftData

struct AccountingEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var syncManager = SyncManager.shared
    @Binding var items: [AccountingItem]

    // 编辑状态
    @State private var editingItems: [EditableAccountingItem] = []
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    @State private var editMode: EditMode = .inactive

    // 默认分类列表
    let categories = ["餐饮", "交通", "购物", "娱乐", "日用", "房租", "水电", "医疗", "教育", "其他"]
    
    // 获取当前主题颜色用于按钮
    private var buttonGradientColors: [Color] {
        let theme = themeManager.currentTheme(for: colorScheme)
        return theme.colors.compactMap { Color(hex: $0) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 主题背景
                ThemedBackgroundView()

                List {
                    ForEach(editingItems.indices, id: \.self) { index in
                        AccountingItemEditCard(
                            item: $editingItems[index],
                            categories: categories,
                            onDelete: {
                                deleteItem(at: index)
                            }
                        )
                        .environmentObject(themeManager)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            deleteItem(at: index)
                        }
                    }

                    // 添加新条目按钮
                    Button(action: addNewItem) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                            Text("添加新条目")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.primary)
                        .background(
                            LinearGradient(
                                colors: buttonGradientColors.isEmpty ? [.blue.opacity(0.2), .purple.opacity(0.2)] : buttonGradientColors.map { $0.opacity(0.3) },
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowSeparator(.hidden)
            }
            .navigationTitle("编辑记账条目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveItems()
                    }
                    .fontWeight(.semibold)
                }
            }
            .environment(\.editMode, $editMode)
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
        .onAppear {
            // 初始化编辑项
            editingItems = items.map { item in
                EditableAccountingItem(
                    amount: String(format: "%.2f", item.amount),
                    title: item.title,
                    category: item.category,
                    date: item.date ?? Date()
                )
            }
        }
    }

    private func addNewItem() {
        let newItem = EditableAccountingItem(
            amount: "",
            title: "",
            category: "其他",
            date: Date()
        )
        editingItems.append(newItem)
    }

    private func deleteItem(at index: Int) {
        editingItems.remove(at: index)
    }

    private func saveItems() {
        // 过滤掉无效的条目并保存到 SwiftData
        let validItems = editingItems.compactMap { item -> Expense? in
            guard let amount = Double(item.amount),
                  !item.title.isEmpty else {
                return nil
            }
            return Expense(
                amount: amount,
                title: item.title,
                categoryName: item.category,
                date: item.date,
                userId: AuthManager.shared.userId
            )
        }

        if validItems.isEmpty {
            saveMessage = "没有有效的记账条目"
            showingSaveAlert = true
        } else {
            // 保存到 SwiftData
            for expense in validItems {
                modelContext.insert(expense)
            }

            // 尝试保存上下文
            do {
                try modelContext.save()

                // Trigger auto-sync after batch adding expenses
                syncManager.autoSyncAfterChange(modelContext: modelContext)

                // 更新绑定的数据（用于返回给调用者）
                items = validItems.map { expense in
                    AccountingItem(
                        amount: expense.amount,
                        title: expense.title,
                        category: expense.category,
                        date: expense.date
                    )
                }
                saveMessage = "成功保存 \(validItems.count) 条记账记录"
            } catch {
                saveMessage = "保存失败: \(error.localizedDescription)"
            }

            showingSaveAlert = true
        }
    }
}

// 可编辑的记账项
struct EditableAccountingItem {
    var amount: String
    var title: String
    var category: String
    var date: Date
}

// 单个编辑卡片
struct AccountingItemEditCard: View {
    @Binding var item: EditableAccountingItem
    let categories: [String]
    let onDelete: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.editMode) var editMode

    @State private var showCategoryPicker = false
    
    private var isEditing: Bool {
        editMode?.wrappedValue == .active
    }

    var body: some View {
        VStack(spacing: 16) {

            // 标题输入
            HStack(alignment: .center, spacing: 12) {
                Text("标题")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 60, alignment: .leading)

                TextField("输入描述", text: $item.title)
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
            .frame(maxWidth: .infinity, alignment: .leading)

            // 金额输入
            HStack(alignment: .center, spacing: 12) {
                Text("金额")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 60, alignment: .leading)

                HStack(spacing: 8) {
                    Text("¥")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    TextField("0.00", text: $item.amount)
                        .font(.system(size: 16))
                        .keyboardType(.decimalPad)
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
            .frame(maxWidth: .infinity, alignment: .leading)

            // 分类选择
            HStack(alignment: .center, spacing: 12) {
                Text("分类")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 60, alignment: .leading)

                Button(action: { showCategoryPicker.toggle() }) {
                    HStack {
                        Text(item.category)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 日期选择
            HStack(alignment: .center, spacing: 12) {
                Text("日期")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 60, alignment: .leading)

                DatePicker("", selection: $item.date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(
                categories: categories,
                selectedCategory: $item.category,
                isPresented: $showCategoryPicker
            )
            .environmentObject(themeManager)
        }
    }
}

// 分类选择器
struct CategoryPickerView: View {
    let categories: [String]
    @Binding var selectedCategory: String
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                // 主题背景
                ThemedBackgroundView()
                
                List(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        isPresented = false
                    }) {
                        HStack {
                            Text(category)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            Spacer()
                            if category == selectedCategory {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(
                        Rectangle()
                            .fill(Material.ultraThinMaterial)
                    )
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("选择分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AccountingEditView(items: .constant([
        AccountingItem(amount: 35.0, title: "午餐", category: "餐饮", date: Date()),
        AccountingItem(amount: 50.0, title: "打车", category: "交通", date: Date())
    ]))
    .environmentObject(ThemeManager.shared)
    .modelContainer(for: Expense.self, inMemory: true)
}
