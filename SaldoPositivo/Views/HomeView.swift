import SwiftUI
import Charts

struct HomeView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @ObservedObject var analyticsViewModel: AnalyticsViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAddExpense = false
    @State private var showingQuickAdd = false
    @State private var showRecentExpenses = false
    @State private var showCategoryBreakdown = false
    @State private var animateCards = false
    @State private var selectedExpenseToEdit: Expense? = nil
    @State private var showingEditExpense = false
    @State private var ringProgress: Double = 0
    @State private var overBudgetPulse = false
    
    private let recentDaysToShow = 7
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    homeHeader
                        .padding(.horizontal)
                        .padding(.top, 4)

                    VStack(spacing: 20) {
                        budgetSummaryCard
                            .padding(.top, 10)
                        recentSpendingCard
                        categoryBreakdownCard
                        recentExpensesSection
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddExpenseView(viewModel: viewModel, onShowFullForm: {
                    showingAddExpense = true
                })
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(viewModel: viewModel)
            }
            .sheet(item: $selectedExpenseToEdit) { expense in
                EditExpenseView(viewModel: viewModel, expense: expense)
            }
            .onAppear {
                // Animate cards when view appears with slight delay between each
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    animateCards = true
                }
                updateRingProgress()
            }
            .onChange(of: analyticsViewModel.totalSpent) { _, _ in
                updateRingProgress()
            }
            .onChange(of: analyticsViewModel.currentBudget) { _, _ in
                updateRingProgress()
            }
            .onChange(of: analyticsViewModel.selectedMonth) { _, _ in
                updateRingProgress()
            }
            .onChange(of: analyticsViewModel.selectedYear) { _, _ in
                updateRingProgress()
            }
        }
    }

    private var homeHeader: some View {
        ZStack {
            InlineMonthYearPicker(
                selectedMonth: $analyticsViewModel.selectedMonth,
                selectedYear: $analyticsViewModel.selectedYear,
                monthsToShow: 36,
                onMonthYearChanged: {
                    analyticsViewModel.calculateAnalytics()
                }
            )
            
            HStack {
                Image("SaldoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .colorMultiply(colorScheme == .light ? Color.green : Color.white)
                    .padding(.leading, -20)
                
                Spacer()
                
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
        .frame(height: 76)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Recent Spending Card

    private var budgetSummaryCard: some View {
        let budget = analyticsViewModel.currentBudget
        let spent = analyticsViewModel.totalSpent
        let remaining = budget - spent
        let progress = budget > 0 ? min(1.0, spent / budget) : 0
        let daysLeft = analyticsViewModel.daysRemainingInMonth
        let perDay = daysLeft > 0 ? max(0, remaining) / Double(daysLeft) : 0
        let progressColor: Color = progress < 0.75 ? .green : (progress < 0.9 ? .orange : .red)

        return VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Text(NSLocalizedString("Budget Summary", comment: "Budget summary title"))
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                if budget > 0 && remaining < 0 {
                    HStack {
                        Spacer()
                        Text(NSLocalizedString("Over Budget", comment: "Over budget badge"))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                            .scaleEffect(overBudgetPulse ? 1.06 : 1.0)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                    overBudgetPulse = true
                                }
                            }
                            .onDisappear {
                                overBudgetPulse = false
                            }
                    }
                }
            }

            if budget > 0 {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 12)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text(remaining >= 0 ? NSLocalizedString("Remaining", comment: "Budget remaining label") : NSLocalizedString("Over Budget", comment: "Over budget label"))
                                .font(.caption2)
                                .foregroundColor(remaining >= 0 ? .secondary : .red)
                            Text(abs(remaining), format: .currency(code: SettingsViewModel.getAppCurrency()))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(remaining >= 0 ? .primary : .red)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Spent", comment: "Total spent label"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(spent, format: .currency(code: SettingsViewModel.getAppCurrency()))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(NSLocalizedString("Budget", comment: "Budget label"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(budget, format: .currency(code: SettingsViewModel.getAppCurrency()))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    HStack(spacing: 8) {
                        if remaining >= 0 {
                            BudgetPill(
                                title: NSLocalizedString("Per day", comment: "Per day label"),
                                value: perDay.formatted(.currency(code: SettingsViewModel.getAppCurrency()))
                            )
                        }
                        BudgetPill(
                            title: NSLocalizedString("Day left", comment: "Days left label"),
                            value: "\(daysLeft)"
                        )
                        BudgetPill(
                            title: NSLocalizedString("Used", comment: "Budget used label"),
                            value: "\(Int(ringProgress * 100))%"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(NSLocalizedString("Budget not set for this month", comment: "Budget not set warning"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(NSLocalizedString("Spent", comment: "Total spent label"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(spent, format: .currency(code: SettingsViewModel.getAppCurrency()))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Button(action: {
                        NotificationCenter.default.post(name: NSNotification.Name("SwitchToAnalyticsBudgetTab"), object: nil)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text(NSLocalizedString("Set Budget", comment: "Set budget action"))
                        }
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground),
                            Color(.tertiarySystemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .offset(y: animateCards ? 0 : -10)
        .opacity(animateCards ? 1 : 0)
    }
    
    private var recentSpendingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Spending")
                .font(.headline)
            
            if analyticsViewModel.dailySpending.isEmpty {
                Text("No recent spending data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                // Get most recent spending data from the daily spending array
                let recentSpending: [DailySpending] = getRecentSpendingData()
                
                // Check if we have any actual spending in this period
                let totalRecentSpending = recentSpending.reduce(0.0) { $0 + $1.amount }
                
                if totalRecentSpending <= 0 {
                Text(String(format: NSLocalizedString("No spending in the last %d days", comment: "No spending in recent days"), recentDaysToShow))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                } else {
                    // Find max value for better scaling
                    let maxValue = recentSpending.map { $0.amount }.max() ?? 0
                    
                    VStack(spacing: 8) {
                        Chart {
                            ForEach(recentSpending, id: \.dayOfMonth) { daily in
                                BarMark(
                                    x: .value("Day", daily.weekday),
                                    y: .value("Amount", daily.amount)
                                )
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.blue.opacity(0.7), .blue],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(6)
                            }
                            
                            if analyticsViewModel.averageDailySpend > 0 {
                                RuleMark(
                                    y: .value("Average", analyticsViewModel.averageDailySpend)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                                .foregroundStyle(Color.green)
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Avg")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                        .padding(4)
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(height: 180)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        // Enforce minimum scale if values are very small
                        .chartYScale(domain: 0...(max(maxValue * 1.2, analyticsViewModel.averageDailySpend * 1.2, 1)))
                        
                        // Add a note about the data
                Text(String(format: NSLocalizedString("Showing spending for the last %d days", comment: "Showing spending for recent days"), recentDaysToShow))
                    .font(.caption)
                    .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .offset(y: animateCards ? 0 : -30)
        .opacity(animateCards ? 1 : 0)
    }
    
    // Helper function to get recent spending data
    private func getRecentSpendingData() -> [DailySpending] {
        var recentSpending: [DailySpending] = []
        
        // For debugging and comprehensive data, let's look at all daily spending
        let allDays = analyticsViewModel.dailySpending
        
        // Find the last 7 days, including today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<recentDaysToShow {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // Find the matching day in our data
                if let day = allDays.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                    recentSpending.insert(day, at: 0) // Insert at front to maintain chronological order
                }
            }
        }
        
        return recentSpending
    }
    
    // MARK: - Category Breakdown Card
    
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Spending by Category")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showCategoryBreakdown.toggle()
                    }
                }) {
                    Label(showCategoryBreakdown ? NSLocalizedString("Hide", comment: "Hide content") : NSLocalizedString("Show", comment: "Show content"), systemImage: showCategoryBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if showCategoryBreakdown {
                if analyticsViewModel.spendingByCategory.isEmpty {
                    Text("No category data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                } else {
                    let sortedCategories = analyticsViewModel.spendingByCategory
                        .sorted(by: { $0.value > $1.value })
                        .prefix(5) // Show top 5 categories
                    
                    VStack(spacing: 12) {
                        ForEach(Array(sortedCategories), id: \.key) { category, amount in
                            HStack(spacing: 12) {
                                // Icon and category
                                HStack(spacing: 8) {
                                    if let iconName = category.iconName {
                                        Image(systemName: iconName)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .frame(width: 30, height: 30)
                                            .background(category.color)
                                            .cornerRadius(8)
                                    } else if let emoji = category.emoji {
                                        Text(emoji)
                                            .font(.system(size: 16))
                                            .frame(width: 30, height: 30)
                                            .background(category.color)
                                            .cornerRadius(8)
                                    } else {
                                        Image(systemName: "tag")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .frame(width: 30, height: 30)
                                            .background(category.color)
                                            .cornerRadius(8)
                                    }
                                    
                                    Text(category.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                // Amount and percentage
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(amount, format: .currency(code: SettingsViewModel.getAppCurrency()))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    if analyticsViewModel.totalSpent > 0 {
                                        Text(String(format: NSLocalizedString("%d%%", comment: "Percentage value"), Int((amount / analyticsViewModel.totalSpent) * 100)))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            if category != sortedCategories.last?.key {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .offset(y: animateCards ? 0 : -20)
        .opacity(animateCards ? 1 : 0)
    }
    
    // MARK: - Recent Expenses Section
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showRecentExpenses.toggle()
                    }
                }) {
                    Label(showRecentExpenses ? NSLocalizedString("Hide", comment: "Hide content") : NSLocalizedString("Show", comment: "Show content"), systemImage: showRecentExpenses ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
//            .padding()
            
            if showRecentExpenses {
                if viewModel.expenses.isEmpty {
                    Text("No expenses yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                } else {
                    // Show most recent 5 expenses
                    let recentExpenses = viewModel.expenses.sorted { $0.date > $1.date }.prefix(5)
                    
                    ForEach(recentExpenses) { expense in
                        Button {
                            selectedExpenseToEdit = expense
                            showingEditExpense = true
                        } label: {
                            HStack(spacing: 12) {
                                // Category icon or emoji
                                ZStack {
                                    if let emoji = expense.category.emoji {
                                        Text(emoji)
                                            .font(.system(size: 14))
                                            .frame(width: 28, height: 28)
                                    } else if let iconName = expense.category.iconName {
                                        Image(systemName: iconName)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .frame(width: 28, height: 28)
                                    }
                                }
                                .background(expense.category.color)
                                .cornerRadius(6)
                                
                                // Title and date
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(expense.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(expense.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Amount
                                Text(expense.price, format: .currency(code: SettingsViewModel.getAppCurrency()))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if expense.id != recentExpenses.last?.id {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                    
                    // View all button
                    Button(action: {
                        // Use NotificationCenter to notify MainTabView to switch to expenses tab
                        NotificationCenter.default.post(name: NSNotification.Name("SwitchToExpensesTab"), object: nil)
                    }) {
                        let viewAllExpensesButton: some View = Text("View All Expenses")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        
                        if #available(iOS 26.0, *) {
                            viewAllExpensesButton
                                .foregroundColor(.white)
                                .glassEffect(.regular.tint(.blue).interactive())
                        } else {
                            viewAllExpensesButton
                                .foregroundColor(.blue)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.accentColor, lineWidth: 1.5)
                                )
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .offset(y: animateCards ? 0 : -10)
        .opacity(animateCards ? 1 : 0)
    }
    
    // MARK: - Helper Methods
    
    private func categoryIcon(for category: ExpenseCategory) -> String? {
        category.iconName
    }

    private func updateRingProgress() {
        let budget = analyticsViewModel.currentBudget
        let spent = analyticsViewModel.totalSpent
        let next = budget > 0 ? min(1.0, spent / budget) : 0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            ringProgress = next
        }
    }
}

private struct BudgetPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    HomeView(
        viewModel: ExpenseViewModel(),
        analyticsViewModel: AnalyticsViewModel(expenses: [])
    )
}
