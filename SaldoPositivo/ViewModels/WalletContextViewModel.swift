import Foundation

@MainActor
final class WalletContextViewModel: ObservableObject {
    static let maxWalletCount = 6

    @Published private(set) var wallets: [WalletSummary] = []
    @Published private(set) var selectedWalletID: String?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repositories: AppRepositoryContainer
    private var currentUserID: String?

    var selectedWallet: WalletSummary? {
        guard let selectedWalletID else { return nil }
        return wallets.first(where: { $0.id == selectedWalletID })
    }

    var hasSharedWallet: Bool {
        wallets.contains(where: { $0.kind == .shared })
    }

    var canCreateMoreWallets: Bool {
        wallets.count < Self.maxWalletCount
    }

    init(repositories: AppRepositoryContainer = .mock()) {
        self.repositories = repositories
        self.selectedWalletID = WalletSelectionStore.shared.selectedWalletID
    }

    func bootstrap(for userID: String) async {
        if currentUserID == userID, !wallets.isEmpty {
            return
        }

        currentUserID = userID
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loaded = try await repositories.wallets.fetchWallets(for: userID)
            wallets = loaded

            if let persisted = WalletSelectionStore.shared.selectedWalletID,
               loaded.contains(where: { $0.id == persisted }) {
                selectedWalletID = persisted
            } else {
                selectedWalletID = loaded.first?.id
                WalletSelectionStore.shared.selectedWalletID = selectedWalletID
            }
        } catch {
            errorMessage = error.localizedDescription
            wallets = []
            selectedWalletID = nil
        }
    }

    func clear() {
        wallets = []
        selectedWalletID = nil
        currentUserID = nil
        errorMessage = nil
        WalletSelectionStore.shared.clear()
    }

    func selectWallet(id: String) {
        guard wallets.contains(where: { $0.id == id }) else { return }
        selectedWalletID = id
        WalletSelectionStore.shared.selectedWalletID = id
    }

    func createWallet(kind: WalletKind) async {
        guard let ownerUserID = currentUserID else { return }
        guard canCreateMoreWallets else {
            errorMessage = "You can create up to \(Self.maxWalletCount) wallets."
            return
        }

        let nextIndex = wallets.filter { $0.kind == kind }.count + 1
        let name: String
        switch kind {
        case .personal:
            name = nextIndex == 1 ? "Personal Wallet" : "Personal Wallet \(nextIndex)"
        case .shared:
            name = nextIndex == 1 ? "Shared Wallet" : "Shared Wallet \(nextIndex)"
        }

        do {
            let created = try await repositories.wallets.createWallet(
                name: name,
                kind: kind,
                ownerUserID: ownerUserID,
                currencyCode: UserDefaults.standard.string(forKey: "selectedCurrency") ?? "EUR"
            )
            wallets.append(created)
            selectWallet(id: created.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createWallet(kind: WalletKind, name: String, currencyCode: String) async {
        guard let ownerUserID = currentUserID else { return }
        guard canCreateMoreWallets else {
            errorMessage = "You can create up to \(Self.maxWalletCount) wallets."
            return
        }
        do {
            let created = try await repositories.wallets.createWallet(
                name: name,
                kind: kind,
                ownerUserID: ownerUserID,
                currencyCode: currencyCode
            )
            wallets.append(created)
            selectWallet(id: created.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateWallet(id: String, name: String, currencyCode: String) async {
        guard let existing = wallets.first(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Wallet name is required."
            return
        }

        let updated = WalletSummary(
            id: existing.id,
            name: trimmedName,
            kind: existing.kind,
            currencyCode: currencyCode,
            ownerUserID: existing.ownerUserID,
            createdAt: existing.createdAt
        )

        do {
            try await repositories.wallets.updateWallet(updated)
            if let index = wallets.firstIndex(where: { $0.id == id }) {
                wallets[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteWallet(id: String) async {
        guard let userID = currentUserID else { return }
        do {
            try await repositories.wallets.deleteWallet(walletID: id, ownerUserID: userID)
            wallets.removeAll { $0.id == id }
            StorageService.clearExpenses(walletID: id)
            StorageService.clearBudgets(walletID: id)
            if selectedWalletID == id {
                selectedWalletID = wallets.first?.id
                WalletSelectionStore.shared.selectedWalletID = selectedWalletID
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
