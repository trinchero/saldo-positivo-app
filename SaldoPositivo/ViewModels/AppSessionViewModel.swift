import Foundation

@MainActor
final class AppSessionViewModel: ObservableObject {
    @Published private(set) var session: AppSession?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let repositories: AppRepositoryContainer

    var isAuthenticated: Bool {
        session != nil
    }

    init(repositories: AppRepositoryContainer = .mock()) {
        self.repositories = repositories
    }

    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }

        do {
            session = try await repositories.auth.currentSession()
        } catch {
            errorMessage = error.localizedDescription
            session = nil
        }
    }

    func signIn(with provider: AuthProvider) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            session = try await repositories.auth.signIn(with: provider)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await repositories.auth.signOut()
            session = nil
            WalletSelectionStore.shared.clear()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
