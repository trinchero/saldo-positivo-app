import Foundation

enum AuthProvider: String, Codable, CaseIterable {
    case apple
    case google
    case email
}

enum WalletKind: String, Codable, CaseIterable {
    case personal
    case shared
}

struct AppUser: Identifiable, Codable, Equatable {
    let id: String
    var email: String
    var displayName: String
}

struct AppSession: Codable, Equatable {
    var user: AppUser
    var provider: AuthProvider
    var createdAt: Date
}

struct WalletSummary: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var kind: WalletKind
    var currencyCode: String
    var ownerUserID: String
    var createdAt: Date
}

struct WalletMembership: Identifiable, Codable, Equatable {
    let id: String
    var walletID: String
    var userID: String
    var role: WalletMemberRole
    var joinedAt: Date
}

enum WalletMemberRole: String, Codable, CaseIterable {
    case owner
    case member
}

enum RepositoryError: LocalizedError {
    case notAuthenticated
    case notFound
    case forbidden
    case invalidInput(String)
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated."
        case .notFound:
            return "Requested resource was not found."
        case .forbidden:
            return "You do not have permission to perform this action."
        case .invalidInput(let message):
            return message
        case .generic(let message):
            return message
        }
    }
}
