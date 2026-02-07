import SwiftUI

struct WalletSwitcherView: View {
    @EnvironmentObject private var walletContext: WalletContextViewModel
    var onEditWalletsTap: (() -> Void)? = nil

    var body: some View {
        Menu {
            if walletContext.wallets.isEmpty {
                Text("No wallets")
            } else {
                ForEach(walletContext.wallets) { wallet in
                    Button {
                        walletContext.selectWallet(id: wallet.id)
                    } label: {
                        HStack {
                            Text(wallet.name)
                            Spacer()
                            if wallet.id == walletContext.selectedWalletID {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                onEditWalletsTap?()
            } label: {
                Label("Edit Wallets", systemImage: "pencil")
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 0) {
                    Text(walletContext.selectedWallet?.name ?? "Select Wallet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(kindTitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
    }

    private var kindTitle: String {
        guard let kind = walletContext.selectedWallet?.kind else { return "Wallet" }
        switch kind {
        case .personal:
            return "Personal"
        case .shared:
            return "Shared"
        }
    }

    private var iconName: String {
        guard let kind = walletContext.selectedWallet?.kind else { return "wallet.pass" }
        switch kind {
        case .personal:
            return "person.crop.circle"
        case .shared:
            return "person.2"
        }
    }
}

#Preview {
    WalletSwitcherView()
        .environmentObject(WalletContextViewModel())
}
