import SwiftUI
import SwiftData

struct ExpensesListView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @ObservedObject var analyticsViewModel: AnalyticsViewModel
    @Query private var customCategories: [CustomCategoryItem]
    @State private var recentlyDeletedExpenses: [Expense] = []
    @State private var showUndoSnackbar: Bool = false
    @State private var undoTimer: Timer? = nil
    @State private var selectedExpenseToEdit: Expense? = nil
    @State private var showingQuickAdd = false
    @State private var showingAddExpense = false
    @State private var showingFilterSheet: Bool = false
    @State private var selectedSortOption: SortOption = .dateDescending
    @State private var searchText: String = ""
    @State private var showEmptyState: Bool = false
    @State private var selectedCategories: Set<ExpenseCategory> = Set(CategoryProvider.systemCategories())
    @State private var isSearchActive = false
    @State private var groupingMode: GroupingMode = .category
    @State private var didSetInitialCategories = false
    
    // Animation states
    @State private var isListLoaded = false
    
    private let monthHistoryLength = 61 // include current month plus ~5 years of history

    init(viewModel: ExpenseViewModel, analyticsViewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
        self.analyticsViewModel = analyticsViewModel
        _customCategories = Query()
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case amountDescending = "Highest Amount"
        case amountAscending = "Lowest Amount"
        case titleAscending = "Title A-Z"
        
        var id: String { self.rawValue }
    }

    enum GroupingMode: String, CaseIterable, Identifiable {
        case category = "By Category"
        case day = "By Day"

        var id: String { self.rawValue }
    }
    
    private var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.price }
    }
    
    private var filteredExpenses: [Expense] {
        var result = viewModel.expenses.filter { expense in
            let month = Calendar.current.component(.month, from: expense.date)
            let year = Calendar.current.component(.year, from: expense.date)
            let matchesDate = month == analyticsViewModel.selectedMonth && year == analyticsViewModel.selectedYear
            let matchesSearch = searchText.isEmpty || 
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.category.displayName.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategories.contains(expense.category)
            
            return matchesDate && matchesSearch && matchesCategory
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .dateDescending:
            result.sort(by: { $0.date > $1.date })
        case .dateAscending:
            result.sort(by: { $0.date < $1.date })
        case .amountDescending:
            result.sort(by: { $0.price > $1.price })
        case .amountAscending:
            result.sort(by: { $0.price < $1.price })
        case .titleAscending:
            result.sort(by: { $0.title < $1.title })
        }
        
        return result
    }
    
    private var groupedExpenses: [ExpenseCategory: [Expense]] {
        Dictionary(grouping: filteredExpenses) { $0.category }
    }
    
    private var visibleCategories: [ExpenseCategory] {
        let categories = Array(groupedExpenses.keys).sorted(by: { $0.displayName < $1.displayName })
        return categories
    }

    private var groupedByDay: [Date: [Expense]] {
        Dictionary(grouping: filteredExpenses) { Calendar.current.startOfDay(for: $0.date) }
    }

    private var visibleDays: [Date] {
        groupedByDay.keys.sorted(by: { $0 > $1 })
    }

    private var allCategories: [ExpenseCategory] {
        CategoryProvider.combinedCategories(custom: customCategories)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    expensesHeader
                        .padding(.horizontal)
                        .padding(.top, 4)
                    
                    // Summary Card
                    if !filteredExpenses.isEmpty {
                        summaryCard
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                    }
                    
                    // Main content
                    if filteredExpenses.isEmpty {
                        emptyStateView
                            .transition(.opacity)
                            .animation(.easeInOut, value: filteredExpenses.isEmpty)
                    } else {
                        List {
                            switch groupingMode {
                            case .category:
                                ForEach(visibleCategories, id: \.self) { category in
                                    Section {
                                        ForEach(groupedExpenses[category] ?? []) { expense in
                                            ExpenseRowContent(expense: expense, onEdit: {
                                                selectedExpenseToEdit = expense
                                            }, onDelete: {
                                                deleteExpenseByID(expense)
                                            })
                                        }
                                    } header: {
                                        HStack {
                                        // Fixed-width icon container
                                        ZStack {
                                            Circle()
                                                .fill(category.color)
                                                .frame(width: 28, height: 28)
                                            
                                            if let emoji = category.emoji {
                                                Text(emoji)
                                                    .font(.caption)
                                            } else if let iconName = category.iconName {
                                                Image(systemName: iconName)
                                                    .foregroundColor(.white)
                                                    .font(.caption)
                                            }
                                        }
                                            
                                            Text(category.displayName)
                                                .font(.headline)
                                            
                                            Spacer()
                                            
                                            // Total for this category
                                            let categoryTotal = (groupedExpenses[category] ?? []).reduce(0) { $0 + $1.price }
                                            Text(categoryTotal, format: .currency(code: SettingsViewModel.getAppCurrency()))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 6)
                                    }
                                }
                            case .day:
                                ForEach(visibleDays, id: \.self) { day in
                                    Section {
                                        ForEach(groupedByDay[day] ?? []) { expense in
                                            ExpenseRowContent(expense: expense, onEdit: {
                                                selectedExpenseToEdit = expense
                                            }, onDelete: {
                                                deleteExpenseByID(expense)
                                            })
                                        }
                                    } header: {
                                        HStack {
                                            Text(day, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
                                                .font(.headline)
                                            
                                            Spacer()
                                            
                                            let dayTotal = (groupedByDay[day] ?? []).reduce(0) { $0 + $1.price }
                                            Text(dayTotal, format: .currency(code: SettingsViewModel.getAppCurrency()))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 6)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .opacity(isListLoaded ? 1 : 0)
                        .animation(.easeIn(duration: 0.3), value: isListLoaded)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search expenses")
            .onChange(of: searchText) {
                withAnimation {
                    isSearchActive = !searchText.isEmpty
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                refreshExpenses()
            }
            .onAppear {
                analyticsViewModel.updateExpenses(viewModel.expenses)
                
                // Animate list appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isListLoaded = true
                    }
                }
                
                applyInitialCategorySelectionIfNeeded()
            }
            .onChange(of: customCategories) {
                applyInitialCategorySelectionIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToExpensesTab"))) { notification in
                guard let raw = notification.userInfo?["category"] as? String,
                      !raw.isEmpty else { return }
                if raw.hasPrefix("custom:") {
                    let id = String(raw.dropFirst("custom:".count))
                    if let custom = customCategories.first(where: { $0.id == id }) {
                        selectedCategories = [.custom(id: custom.id, name: custom.name, emoji: custom.emoji)]
                        searchText = ""
                    }
                } else if let category = Category(rawValue: raw) {
                    selectedCategories = [.system(category)]
                    searchText = ""
                }
            }
            .onChange(of: viewModel.expenses) {
                analyticsViewModel.updateExpenses(viewModel.expenses)
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddExpenseView(viewModel: viewModel, onShowFullForm: {
                    showingAddExpense = true
                })
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(viewModel: viewModel)
            }
            .sheet(item: $selectedExpenseToEdit) { expenseToEdit in
                // Use ID parameter to force view refresh
                EditExpenseView(viewModel: viewModel, expense: expenseToEdit)
                    .id(expenseToEdit.id) // Force view to refresh completely on each presentation
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterCategoriesView(selectedCategories: $selectedCategories)
                    .presentationDetents([.medium])
            }
            .overlay(
                VStack {
                    Spacer()
                    if showUndoSnackbar {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Expense deleted")
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Undo") {
                                undoDelete()
                            }
                            .foregroundColor(.yellow)
                            .fontWeight(.bold)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: showUndoSnackbar)
                    }
                }
            )
        }
    }

    private var expensesHeader: some View {
        ZStack {
            InlineMonthYearPicker(
                selectedMonth: $analyticsViewModel.selectedMonth,
                selectedYear: $analyticsViewModel.selectedYear,
                monthsToShow: monthHistoryLength,
                onMonthYearChanged: {
                    analyticsViewModel.calculateAnalytics()
                }
            )

            HStack(spacing: 12) {
                Menu {
                    Picker("Sort by", selection: $selectedSortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.callout)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }

                Button(action: {
                    showingFilterSheet = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.callout)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }

                Spacer()

            Menu {
                Picker(NSLocalizedString("Group", comment: "Group"), selection: $groupingMode) {
                    ForEach(GroupingMode.allCases) { mode in
                        Text(NSLocalizedString(mode.rawValue, comment: "Grouping mode")).tag(mode)
                    }
                }
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.callout)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }

                Button(action: {
                    showingQuickAdd = true
                }) {
                    HStack(spacing: 6) {
                        Text(NSLocalizedString("Add", comment: "Add"))
                            .fontWeight(.semibold)
                    }
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }
            }
        }
        .frame(height: 72)
    }

    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            // Total amount for selected month
            HStack(spacing: 12) {
                VStack(alignment: .leading,     spacing: 4) {
                    Text(String(format: NSLocalizedString("Total for %@", comment: "Total for month"), Calendar.current.monthSymbols[analyticsViewModel.selectedMonth - 1]))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(totalAmount, format: .currency(code: SettingsViewModel.getAppCurrency()))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Number of expenses
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Expenses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(filteredExpenses.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            // Budget progress if available
            if analyticsViewModel.currentBudget > 0 {
                VStack(spacing: 6) {
                    HStack {
                        Text("Monthly Budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(totalAmount, format: .currency(code: SettingsViewModel.getAppCurrency()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("of")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(analyticsViewModel.currentBudget, format: .currency(code: SettingsViewModel.getAppCurrency()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    let progress = min(1.0, totalAmount / analyticsViewModel.currentBudget)
                    let progressColor: Color = progress < 0.75 ? .blue : (progress < 0.9 ? .orange : .red)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor)
                                .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.6))
                .padding()
            
            Text("No Expenses Found")
                .font(.title2)
                .fontWeight(.bold)
            
            if !searchText.isEmpty {
                Text("Try adjusting your search or filters")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else if selectedCategories.count < allCategories.count {
                Text("Try selecting more categories in the filter")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    selectedCategories = Set(allCategories)
                }) {
                    Text("Reset Filters")
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor, lineWidth: 1)
                        )
                }
                .padding(.top, 8)
            } else {
                Text(String(format: NSLocalizedString("Add your first expense for %@ %@", comment: "Add first expense for month and year"), Calendar.current.monthSymbols[analyticsViewModel.selectedMonth - 1], String(analyticsViewModel.selectedYear)))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    showingQuickAdd = true
                }) {
                    let addExpenseLabel: some View =
                        Label("Add Expense", systemImage: "plus")
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                    
                    if #available(iOS 26.0, *) {
                        addExpenseLabel
                            .glassEffect(.regular.tint(.blue).interactive())
                        
                    } else {
                        addExpenseLabel
                            .background(Color.accentColor)
                            .cornerRadius(10)

                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func refreshExpenses() {
        viewModel.loadExpenses()
    }

    private func deleteExpenseByID(_ expense: Expense) {
        if let index = viewModel.expenses.firstIndex(where: { $0.id == expense.id }) {
            recentlyDeletedExpenses = [expense]
            viewModel.expenses.remove(at: index)
            viewModel.saveExpenses()
            
            showUndoSnackbar = true
            
            undoTimer?.invalidate()
            undoTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                showUndoSnackbar = false
                recentlyDeletedExpenses.removeAll()
            }
        }
    }
    
    private func undoDelete() {
        undoTimer?.invalidate()
        viewModel.expenses.append(contentsOf: recentlyDeletedExpenses)
        viewModel.saveExpenses()
        recentlyDeletedExpenses.removeAll()
        showUndoSnackbar = false
    }

    private func applyInitialCategorySelectionIfNeeded() {
        guard !didSetInitialCategories else { return }
        didSetInitialCategories = true
        let combined = Set(allCategories)
        if selectedCategories.isEmpty {
            selectedCategories = combined
        } else if !combined.isSubset(of: selectedCategories) {
            selectedCategories = combined
        }
    }
    
}

#Preview {
    ExpensesListView(
        viewModel: ExpenseViewModel(),
        analyticsViewModel: AnalyticsViewModel(expenses: [])
    )
}

// MARK: - Expense Row View

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // Date column
            VStack(alignment: .center, spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(monthShort)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 40)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
            
            // Title and details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Price
            Text(expense.price, format: .currency(code: SettingsViewModel.getAppCurrency()))
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
        }
        .padding(.vertical, 6)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: expense.date)
    }
    
    private var monthShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: expense.date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy"
        return formatter.string(from: expense.date)
    }
}

// MARK: - Filter Categories View

struct FilterCategoriesView: View {
    @Binding var selectedCategories: Set<ExpenseCategory>
    @Environment(\.dismiss) private var dismiss
    @Query private var customCategories: [CustomCategoryItem]
    
    @State private var tempSelectedCategories: Set<ExpenseCategory>
    
    init(selectedCategories: Binding<Set<ExpenseCategory>>) {
        self._selectedCategories = selectedCategories
        self._tempSelectedCategories = State(initialValue: selectedCategories.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        ForEach(allCategories, id: \.id) { category in
                            HStack {
                                // Fixed-width icon container
                                ZStack {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 28, height: 28)
                                    
                                    if let emoji = category.emoji {
                                        Text(emoji)
                                            .font(.caption)
                                    } else if let iconName = category.iconName {
                                        Image(systemName: iconName)
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    }
                                }
                                
                                Text(category.displayName)
                                    .font(.body)
                                
                                Spacer()
                                
                                if tempSelectedCategories.contains(category) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if tempSelectedCategories.contains(category) {
                                    if tempSelectedCategories.count > 1 {  // Prevent removing all categories
                                        tempSelectedCategories.remove(category)
                                    }
                                } else {
                                    tempSelectedCategories.insert(category)
                                }
                            }
                        }
                    } header: {
                        Text("Categories")
                    } footer: {
                        Text("Select which expense categories to display")
                    }
                }
                
//                HStack(spacing: 12) {
//                    Button {
//                        tempSelectedCategories = Set(Category.allCases)
//                    } label: {
//                        let selectAllButton: some View = Text("Select All")
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 12)
//                        if #available(iOS 26.0, *) {
//                            selectAllButton
//                                .foregroundColor(.white)
//                                .glassEffect(.regular.tint(.blue).interactive())
//                        } else {
//                            selectAllButton
//                                .foregroundColor(.accentColor)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 10)
//                                        .stroke(Color.accentColor, lineWidth: 1)
//                                )
//                        }
//                    }
//                    
//                    Button {
//                        selectedCategories = tempSelectedCategories
//                        dismiss()
//                    } label: {
//                        let applyButton: some View = Text("Apply")
//                            .foregroundColor(.white)
//                            .padding(.vertical, 12)
//                            .frame(maxWidth: .infinity)
//                        if #available(iOS 26.0, *) {
//                            applyButton
//                                .glassEffect(.regular.tint(.blue).interactive())
//                        } else {
//                            applyButton
//                                .background(
//                                    RoundedRectangle(cornerRadius: 10)
//                                        .fill(Color.accentColor)
//                                )
//                        }
//                    }
//                }
//                .padding()
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        selectedCategories = tempSelectedCategories
                        dismiss()
                    }
                    
                }
            }
        }
    }
    
    private var allCategories: [ExpenseCategory] {
        CategoryProvider.combinedCategories(custom: customCategories)
    }
}

struct ExpenseRowContent: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ExpenseRowView(expense: expense)
            .contentShape(Rectangle())
            .onTapGesture {
                print("DEBUG: Tap gesture on expense with ID \(expense.id), title \(expense.title)")
                onEdit()
                print("DEBUG: Directly setting selectedExpenseToEdit")
            }
            .contextMenu {
                Button(action: {
                    onEdit()
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    onDelete()
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing) {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
    }
}

#Preview {
    ExpensesListView(
        viewModel: ExpenseViewModel(),
        analyticsViewModel: AnalyticsViewModel(expenses: [])
    )
}
