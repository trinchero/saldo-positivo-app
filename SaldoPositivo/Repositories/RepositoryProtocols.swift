import Foundation

protocol AuthRepository {
    func currentSession() async throws -> AppSession?
    func signIn(with provider: AuthProvider) async throws -> AppSession
    func signOut() async throws
}

protocol WalletRepository {
    func fetchWallets(for userID: String) async throws -> [WalletSummary]
    func createWallet(
        name: String,
        kind: WalletKind,
        ownerUserID: String,
        currencyCode: String
    ) async throws -> WalletSummary
    func updateWallet(_ wallet: WalletSummary) async throws
    func deleteWallet(walletID: String, ownerUserID: String) async throws
}

protocol ExpenseRepository {
    func fetchExpenses(walletID: String, month: Date?) async throws -> [Expense]
    func upsertExpense(_ expense: Expense, walletID: String) async throws
    func deleteExpense(id: UUID, walletID: String) async throws
}

protocol BudgetRepository {
    func fetchBudgets(walletID: String) async throws -> [String: Double]
    func setBudget(monthYear: String, amount: Double, walletID: String) async throws
    func resetBudgets(walletID: String) async throws
}
