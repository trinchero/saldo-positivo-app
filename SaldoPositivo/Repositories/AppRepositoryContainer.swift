import Foundation

struct AppRepositoryContainer {
    let auth: any AuthRepository
    let wallets: any WalletRepository
    let expenses: any ExpenseRepository
    let budgets: any BudgetRepository

    static func mock() -> AppRepositoryContainer {
        AppRepositoryContainer(
            auth: MockAuthRepository(),
            wallets: MockWalletRepository(),
            expenses: MockExpenseRepository(),
            budgets: MockBudgetRepository()
        )
    }
}

final class WalletSelectionStore {
    static let shared = WalletSelectionStore()

    private let selectedWalletIDKey = "selected_wallet_id"

    var selectedWalletID: String? {
        get { UserDefaults.standard.string(forKey: selectedWalletIDKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedWalletIDKey)
            NotificationCenter.default.post(name: .walletDidChange, object: nil)
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: selectedWalletIDKey)
        NotificationCenter.default.post(name: .walletDidChange, object: nil)
    }
}
