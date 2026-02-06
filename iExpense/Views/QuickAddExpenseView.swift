import SwiftUI
import SwiftData

struct QuickAddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ExpenseViewModel
    let onShowFullForm: (() -> Void)?
    @Query private var customCategories: [CustomCategoryItem]

    @FocusState private var isAmountFocused: Bool

    @State private var title: String = ""
    @State private var price: String = ""
    @State private var selectedCategory: ExpenseCategory
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    @State private var showNotes: Bool = false
    @State private var showInlineValidation = false
    @State private var validationMessage = ""
    @State private var animateSuccess = false
    @State private var didSetInitialCategory = false

    private var currencySymbol: String {
        let locale = Locale.current
        let currencyCode = SettingsViewModel.getAppCurrency()
        return locale.localizedCurrencySymbol(forCurrencyCode: currencyCode) ?? currencyCode
    }

    init(viewModel: ExpenseViewModel, onShowFullForm: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onShowFullForm = onShowFullForm
        let defaultCategory = UserDefaults.standard.string(forKey: "defaultCategory") ?? Category.food.rawValue
        let initial = Category(rawValue: defaultCategory) ?? .food
        _selectedCategory = State(initialValue: .system(initial))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerSection

                        CardView(title: NSLocalizedString("Amount", comment: "Amount")) {
                            CurrencyFormField(
                                label: NSLocalizedString("Amount", comment: "Amount"),
                                amount: $price,
                                currencySymbol: currencySymbol,
                                clearAction: { price = "" }
                            )
                            .padding(.horizontal)
                            .focused($isAmountFocused)
                        }

                        CardView(title: NSLocalizedString("Title", comment: "Title")) {
                            TextFormField(
                                label: NSLocalizedString("Title", comment: "Title"),
                                text: $title,
                                placeholder: NSLocalizedString("Expense title", comment: "Expense title"),
                                leadingIcon: "pencil"
                            )
                            .padding(.horizontal)
                        }

                        CardView(title: NSLocalizedString("Category", comment: "Category")) {
                            CategoryGrid(
                                categories: allCategories,
                                selectedCategory: $selectedCategory
                            )
                                .padding(.horizontal)
                        }

                        dateSection

                        notesSection

                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                if animateSuccess {
                    successOverlay
                }
                
                if showInlineValidation {
                    validationToast
                }
            }
            .navigationTitle(NSLocalizedString("Quick Add", comment: "Quick add title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Save", comment: "Save")) {
                        saveExpense()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isAmountFocused = true
                }
                applyLastUsedCategoryIfNeeded()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("Quickly add an expense", comment: "Quick add headline"))
                .font(.headline)
            Text(NSLocalizedString("Most fields are optional - just enter an amount.", comment: "Quick add subheadline"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateSection: some View {
        CardView(title: NSLocalizedString("Date", comment: "Date")) {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Button(action: { selectedDate = Date() }) {
                        Text(NSLocalizedString("Today", comment: "Today"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedDate.isToday ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date() }) {
                        Text(NSLocalizedString("Yesterday", comment: "Yesterday"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedDate.isYesterday ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PressableButtonStyle())
                }

                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var notesSection: some View {
        CardView(title: NSLocalizedString("Notes", comment: "Notes")) {
            VStack(alignment: .leading, spacing: 10) {
                if showNotes {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                            .frame(minHeight: 100)

                        TextEditor(text: $notes)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(8)
                            .frame(minHeight: 100)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button(action: { showNotes = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.pencil")
                            Text(NSLocalizedString("Add note", comment: "Add note"))
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.98, opacity: 0.95))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var saveButton: some View {
        Button(action: saveExpense) {
            HStack {
                Spacer()
                Text(NSLocalizedString("Save Expense", comment: "Save expense"))
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .foregroundColor(.white)
            .background(isFormValid ? Color.accentColor : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isFormValid)
        .buttonStyle(PressableButtonStyle())
    }

    private var isFormValid: Bool {
        !price.isEmpty && !title.isEmpty
    }

    private func saveExpense() {
        showInlineValidation = false
        
        if title.isEmpty {
            validationMessage = NSLocalizedString("Please enter a title for your expense.", comment: "Validation")
            showValidationToast()
            HapticFeedback.error()
            return
        }
        
        if price.isEmpty {
            validationMessage = NSLocalizedString("Please enter the expense amount.", comment: "Validation")
            showValidationToast()
            HapticFeedback.error()
            return
        }

        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        guard let priceValue = Double(normalizedPrice) else {
            validationMessage = NSLocalizedString("Please enter a valid amount.", comment: "Validation")
            showValidationToast()
            HapticFeedback.error()
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            animateSuccess = true
        }

        let newExpense = viewModel.addExpense(
            title: title,
            price: priceValue,
            date: selectedDate,
            category: selectedCategory
        )

        UserDefaults.standard.set(lastUsedCategoryKey(selectedCategory), forKey: "lastUsedCategoryKey")

        if !notes.isEmpty {
            let notesKey = "notes_\(newExpense.id.uuidString)"
            UserDefaults.standard.set(notes, forKey: notesKey)
            UserDefaults.standard.synchronize()
        }

        HapticFeedback.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            dismiss()
        }
    }

    private func showValidationToast() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showInlineValidation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.2)) {
                showInlineValidation = false
            }
        }
    }

    private var validationToast: some View {
        VStack {
            Spacer()
            Text(validationMessage)
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.85))
                .clipShape(Capsule())
                .shadow(radius: 6)
                .padding(.bottom, 18)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var allCategories: [ExpenseCategory] {
        CategoryProvider.combinedCategories(custom: customCategories)
    }

    private func applyLastUsedCategoryIfNeeded() {
        guard !didSetInitialCategory else { return }
        didSetInitialCategory = true
        if let key = UserDefaults.standard.string(forKey: "lastUsedCategoryKey"),
           let resolved = resolveCategory(from: key) {
            selectedCategory = resolved
            return
        }
        if let legacy = UserDefaults.standard.string(forKey: "lastUsedCategory"),
           let legacyCategory = Category(rawValue: legacy) {
            selectedCategory = .system(legacyCategory)
        }
    }

    private func resolveCategory(from key: String) -> ExpenseCategory? {
        if key.hasPrefix("custom:") {
            let id = key.replacingOccurrences(of: "custom:", with: "")
            return allCategories.first(where: { $0.id == id })
        }
        if key.hasPrefix("system:") {
            let raw = key.replacingOccurrences(of: "system:", with: "")
            return allCategories.first(where: { $0.id == raw })
        }
        return nil
    }

    private func lastUsedCategoryKey(_ category: ExpenseCategory) -> String {
        switch category.kind {
        case .system:
            return "system:\(category.id)"
        case .custom:
            return "custom:\(category.id)"
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.green)

                Text(NSLocalizedString("Expense Added!", comment: "Expense added"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.85))
                    .blur(radius: 0.5)
            )
            .scaleEffect(animateSuccess ? 1.0 : 0.6)
            .opacity(animateSuccess ? 1.0 : 0)
            .animation(.spring(), value: animateSuccess)
        }
    }
}

private extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
}

#Preview {
    QuickAddExpenseView(viewModel: ExpenseViewModel())
}
