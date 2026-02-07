import Foundation

struct StorageService {
    static let appGroupID = "group.com.vintuss.Inpenso"

    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private static let legacyExpensesKey = "expenses"
    private static let legacyBudgetsKey = "budgets"
    private static let legacyMigrationCompletedKey = "wallet_storage_legacy_migrated"

    static let defaultWalletID = "personal_default_wallet"
    private static let selectedWalletIDKey = "selected_wallet_id"

    private static func expensesKey(for walletID: String) -> String {
        "expenses_\(walletID)"
    }

    private static func budgetsKey(for walletID: String) -> String {
        "budgets_\(walletID)"
    }

    private static func currentWalletID() -> String {
        UserDefaults.standard.string(forKey: selectedWalletIDKey) ?? defaultWalletID
    }

    static func saveExpenses(_ expenses: [Expense]) {
        saveExpenses(expenses, walletID: currentWalletID())
    }

    static func saveExpenses(_ expenses: [Expense], walletID: String) {
        guard let userDefaults = userDefaults else { return }
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(expenses)
            userDefaults.set(data, forKey: expensesKey(for: walletID))
        } catch {
            // Error handling without print
        }
    }

    static func loadExpenses() -> [Expense] {
        loadExpenses(walletID: currentWalletID())
    }

    static func loadExpenses(walletID: String) -> [Expense] {
        migrateLegacyDataIfNeeded(walletID: walletID)
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: expensesKey(for: walletID)) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            let expenses = try decoder.decode([Expense].self, from: data)
            return expenses
        } catch {
            // Error handling without print
            return []
        }
    }
    
    static func saveBudgets(_ budgets: [String: Double]) {
        saveBudgets(budgets, walletID: currentWalletID())
    }

    static func saveBudgets(_ budgets: [String: Double], walletID: String) {
        guard let userDefaults = userDefaults else { return }
        do {
            let data = try JSONEncoder().encode(budgets)
            userDefaults.set(data, forKey: budgetsKey(for: walletID))
        } catch {
            // Error handling without print
        }
    }

    static func loadBudgets() -> [String: Double] {
        loadBudgets(walletID: currentWalletID())
    }

    static func loadBudgets(walletID: String) -> [String: Double] {
        migrateLegacyDataIfNeeded(walletID: walletID)
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: budgetsKey(for: walletID)) else {
            return [:]
        }
        do {
            let budgets = try JSONDecoder().decode([String: Double].self, from: data)
            return budgets
        } catch {
            // Error handling without print
            return [:]
        }
    }

    static func clearExpenses() {
        clearExpenses(walletID: currentWalletID())
    }

    static func clearExpenses(walletID: String) {
        guard let userDefaults = userDefaults else { return }
        userDefaults.removeObject(forKey: expensesKey(for: walletID))
    }

    static func clearBudgets(walletID: String) {
        guard let userDefaults = userDefaults else { return }
        userDefaults.removeObject(forKey: budgetsKey(for: walletID))
    }

    static func clearAllWalletData() {
        guard let userDefaults = userDefaults else { return }
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix("expenses_") || key.hasPrefix("budgets_") {
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.removeObject(forKey: legacyExpensesKey)
        userDefaults.removeObject(forKey: legacyBudgetsKey)
        userDefaults.removeObject(forKey: legacyMigrationCompletedKey)
    }

    private static func migrateLegacyDataIfNeeded(walletID: String) {
        guard let userDefaults = userDefaults else { return }

        if userDefaults.bool(forKey: legacyMigrationCompletedKey) {
            return
        }

        let legacyExpensesData = userDefaults.data(forKey: legacyExpensesKey)
        let legacyBudgetsData = userDefaults.data(forKey: legacyBudgetsKey)

        // Nothing to migrate anymore.
        if legacyExpensesData == nil && legacyBudgetsData == nil {
            userDefaults.set(true, forKey: legacyMigrationCompletedKey)
            return
        }

        let scopedExpensesKey = expensesKey(for: walletID)
        if userDefaults.data(forKey: scopedExpensesKey) == nil,
           let legacyData = legacyExpensesData {
            userDefaults.set(legacyData, forKey: scopedExpensesKey)
        }

        let scopedBudgetsKey = budgetsKey(for: walletID)
        if userDefaults.data(forKey: scopedBudgetsKey) == nil,
           let legacyData = legacyBudgetsData {
            userDefaults.set(legacyData, forKey: scopedBudgetsKey)
        }

        // Prevent copying legacy data into newly created wallets.
        userDefaults.removeObject(forKey: legacyExpensesKey)
        userDefaults.removeObject(forKey: legacyBudgetsKey)
        userDefaults.set(true, forKey: legacyMigrationCompletedKey)
    }
}
