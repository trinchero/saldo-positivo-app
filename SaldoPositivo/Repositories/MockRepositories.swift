import Foundation

actor MockAuthRepository: AuthRepository {
    private let sessionKey = "mock_auth_session"
    private var session: AppSession?

    init(initialSession: AppSession? = nil) {
        if let initialSession {
            self.session = initialSession
        } else {
            self.session = Self.loadPersistedSession(forKey: sessionKey)
        }
    }

    func currentSession() async throws -> AppSession? {
        session
    }

    func signIn(with provider: AuthProvider) async throws -> AppSession {
        if let existing = session {
            return existing
        }

        let user = AppUser(
            id: UUID().uuidString,
            email: "andrea_trinchero@icloud.com",
            displayName: "Andrea"
        )

        let newSession = AppSession(user: user, provider: provider, createdAt: Date())
        session = newSession
        Self.persist(session: newSession, forKey: sessionKey)
        return newSession
    }

    func signOut() async throws {
        session = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    private static func loadPersistedSession(forKey key: String) -> AppSession? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(AppSession.self, from: data)
    }

    private static func persist(session: AppSession, forKey key: String) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}

actor MockWalletRepository: WalletRepository {
    private let maxWalletCount = 6
    private let walletsKey = "mock_wallets_by_user"
    private var walletsByUserID: [String: [WalletSummary]]

    init(seedWalletsByUserID: [String: [WalletSummary]] = [:]) {
        if seedWalletsByUserID.isEmpty {
            self.walletsByUserID = Self.loadPersistedWallets(forKey: walletsKey)
        } else {
            self.walletsByUserID = seedWalletsByUserID
            Self.persist(walletsByUserID: seedWalletsByUserID, forKey: walletsKey)
        }
    }

    func fetchWallets(for userID: String) async throws -> [WalletSummary] {
        if let existing = walletsByUserID[userID] {
            return existing
        }

        let defaultWallet = WalletSummary(
            id: StorageService.defaultWalletID,
            name: "Personal Wallet",
            kind: .personal,
            currencyCode: UserDefaults.standard.string(forKey: "selectedCurrency") ?? "EUR",
            ownerUserID: userID,
            createdAt: Date()
        )

        walletsByUserID[userID] = [defaultWallet]
        Self.persist(walletsByUserID: walletsByUserID, forKey: walletsKey)
        return [defaultWallet]
    }

    func createWallet(
        name: String,
        kind: WalletKind,
        ownerUserID: String,
        currencyCode: String
    ) async throws -> WalletSummary {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw RepositoryError.invalidInput("Wallet name is required.")
        }

        var userWallets = walletsByUserID[ownerUserID] ?? []
        guard userWallets.count < maxWalletCount else {
            throw RepositoryError.invalidInput("You can create up to \(maxWalletCount) wallets.")
        }
        let wallet = WalletSummary(
            id: UUID().uuidString,
            name: trimmedName,
            kind: kind,
            currencyCode: currencyCode,
            ownerUserID: ownerUserID,
            createdAt: Date()
        )
        userWallets.append(wallet)
        walletsByUserID[ownerUserID] = userWallets
        Self.persist(walletsByUserID: walletsByUserID, forKey: walletsKey)
        return wallet
    }

    func updateWallet(_ wallet: WalletSummary) async throws {
        guard var userWallets = walletsByUserID[wallet.ownerUserID],
              let index = userWallets.firstIndex(where: { $0.id == wallet.id }) else {
            throw RepositoryError.notFound
        }
        userWallets[index] = wallet
        walletsByUserID[wallet.ownerUserID] = userWallets
        Self.persist(walletsByUserID: walletsByUserID, forKey: walletsKey)
    }

    func deleteWallet(walletID: String, ownerUserID: String) async throws {
        guard var userWallets = walletsByUserID[ownerUserID] else {
            throw RepositoryError.notFound
        }
        guard userWallets.contains(where: { $0.id == walletID }) else {
            throw RepositoryError.notFound
        }

        if userWallets.count <= 1 {
            throw RepositoryError.invalidInput("At least one wallet is required.")
        }

        userWallets.removeAll { $0.id == walletID }
        walletsByUserID[ownerUserID] = userWallets
        Self.persist(walletsByUserID: walletsByUserID, forKey: walletsKey)
    }

    private static func loadPersistedWallets(forKey key: String) -> [String: [WalletSummary]] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: [WalletSummary]].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func persist(walletsByUserID: [String: [WalletSummary]], forKey key: String) {
        guard let data = try? JSONEncoder().encode(walletsByUserID) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}

actor MockExpenseRepository: ExpenseRepository {
    private var expensesByWalletID: [String: [Expense]]

    init(seedExpensesByWalletID: [String: [Expense]] = [:]) {
        self.expensesByWalletID = seedExpensesByWalletID
    }

    func fetchExpenses(walletID: String, month: Date?) async throws -> [Expense] {
        let allExpenses = expensesByWalletID[walletID] ?? []
        guard let month else { return allExpenses }

        let calendar = Calendar.current
        return allExpenses.filter { expense in
            calendar.isDate(expense.date, equalTo: month, toGranularity: .month)
        }
    }

    func upsertExpense(_ expense: Expense, walletID: String) async throws {
        var expenses = expensesByWalletID[walletID] ?? []

        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        } else {
            expenses.append(expense)
        }

        expensesByWalletID[walletID] = expenses
    }

    func deleteExpense(id: UUID, walletID: String) async throws {
        guard var expenses = expensesByWalletID[walletID] else { return }
        expenses.removeAll { $0.id == id }
        expensesByWalletID[walletID] = expenses
    }
}

actor MockBudgetRepository: BudgetRepository {
    private var budgetsByWalletID: [String: [String: Double]]

    init(seedBudgetsByWalletID: [String: [String: Double]] = [:]) {
        self.budgetsByWalletID = seedBudgetsByWalletID
    }

    func fetchBudgets(walletID: String) async throws -> [String: Double] {
        budgetsByWalletID[walletID] ?? [:]
    }

    func setBudget(monthYear: String, amount: Double, walletID: String) async throws {
        guard amount >= 0 else {
            throw RepositoryError.invalidInput("Budget cannot be negative.")
        }

        var walletBudgets = budgetsByWalletID[walletID] ?? [:]
        walletBudgets[monthYear] = amount
        budgetsByWalletID[walletID] = walletBudgets
    }

    func resetBudgets(walletID: String) async throws {
        budgetsByWalletID[walletID] = [:]
    }
}
