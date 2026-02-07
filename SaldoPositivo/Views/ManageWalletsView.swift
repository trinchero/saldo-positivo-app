import SwiftUI

struct ManageWalletsView: View {
    @EnvironmentObject private var walletContext: WalletContextViewModel

    @State private var showingCreateSheet = false
    @State private var editingWallet: WalletSummary?
    @State private var deletingWallet: WalletSummary?
    @State private var showingDeleteConfirmation = false
    @State private var showingWalletError = false

    var body: some View {
        List {
            ForEach(walletContext.wallets) { wallet in
                walletRow(wallet)
            }
        }
        .navigationTitle("Manage Wallets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!walletContext.canCreateMoreWallets)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            WalletEditorSheet(
                mode: .create,
                onSave: { name, kind, currencyCode in
                    Task {
                        await walletContext.createWallet(kind: kind, name: name, currencyCode: currencyCode)
                    }
                }
            )
        }
        .sheet(item: $editingWallet) { wallet in
            WalletEditorSheet(
                mode: .edit(wallet),
                onSave: { name, _, currencyCode in
                    Task {
                        await walletContext.updateWallet(id: wallet.id, name: name, currencyCode: currencyCode)
                    }
                }
            )
        }
        .alert("Delete Wallet", isPresented: $showingDeleteConfirmation, presenting: deletingWallet) { wallet in
            Button("Delete", role: .destructive) {
                Task {
                    await walletContext.deleteWallet(id: wallet.id)
                    deletingWallet = nil
                }
            }
            Button("Cancel", role: .cancel) {
                deletingWallet = nil
            }
        } message: { wallet in
            Text("Delete \"\(wallet.name)\"? This permanently removes this wallet and all its local expenses and budgets.")
        }
        .alert("Wallet Error", isPresented: $showingWalletError) {
            Button("OK") { walletContext.errorMessage = nil }
        } message: {
            Text(walletContext.errorMessage ?? "")
        }
        .onChange(of: walletContext.errorMessage) { _, newValue in
            showingWalletError = newValue != nil
        }
        .safeAreaInset(edge: .bottom) {
            if !walletContext.canCreateMoreWallets {
                Text("Maximum \(WalletContextViewModel.maxWalletCount) wallets reached.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private func walletRow(_ wallet: WalletSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name)
                        .font(.headline)
                    Text(wallet.kind == .personal ? "Personal" : "Shared")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if wallet.id == walletContext.selectedWalletID {
                    Text("Current")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }

            HStack {
                Text(currencyTitle(code: wallet.currencyCode))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if wallet.id != walletContext.selectedWalletID {
                    Button("Set Current") {
                        walletContext.selectWallet(id: wallet.id)
                    }
                    .buttonStyle(.borderless)
                }

                Button {
                    editingWallet = wallet
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    deletingWallet = wallet
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(walletContext.wallets.count <= 1)
            }
        }
        .padding(.vertical, 6)
    }

    private func currencyTitle(code: String) -> String {
        if let currency = availableCurrencies.first(where: { $0.code == code }) {
            return "\(currency.symbol) \(currency.name)"
        }
        return code
    }
}

private struct WalletEditorSheet: View {
    enum Mode {
        case create
        case edit(WalletSummary)
    }

    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    let onSave: (_ name: String, _ kind: WalletKind, _ currencyCode: String) -> Void

    @State private var name: String = ""
    @State private var kind: WalletKind = .personal
    @State private var currencyCode: String = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "EUR"

    var body: some View {
        NavigationView {
            Form {
                TextField("Wallet Name", text: $name)

                if case .create = mode {
                    Picker("Type", selection: $kind) {
                        Text("Personal").tag(WalletKind.personal)
                        Text("Shared").tag(WalletKind.shared)
                    }
                }

                Picker("Currency", selection: $currencyCode) {
                    ForEach(availableCurrencies, id: \.code) { currency in
                        Text("\(currency.symbol) \(currency.name) (\(currency.code))")
                            .tag(currency.code)
                    }
                }
            }
            .navigationTitle(modeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, kind, currencyCode)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            if case .edit(let wallet) = mode {
                name = wallet.name
                kind = wallet.kind
                currencyCode = wallet.currencyCode
            }
        }
    }

    private var modeTitle: String {
        switch mode {
        case .create:
            return "New Wallet"
        case .edit:
            return "Edit Wallet"
        }
    }
}

#Preview {
    NavigationView {
        ManageWalletsView()
            .environmentObject(WalletContextViewModel())
    }
}
