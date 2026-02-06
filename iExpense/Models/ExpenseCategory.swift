import Foundation
import SwiftUI

struct ExpenseCategory: Identifiable, Codable, Equatable, Hashable {
    enum Kind: String, Codable {
        case system
        case custom
    }

    var id: String
    var name: String
    var kind: Kind
    var emoji: String?
    var systemRaw: String?

    static func == (lhs: ExpenseCategory, rhs: ExpenseCategory) -> Bool {
        lhs.id == rhs.id && lhs.kind == rhs.kind
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(kind)
    }

    init(id: String, name: String, kind: Kind, emoji: String? = nil, systemRaw: String? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.emoji = emoji
        self.systemRaw = systemRaw
    }

    static func system(_ category: Category) -> ExpenseCategory {
        ExpenseCategory(id: category.rawValue, name: category.displayName, kind: .system, emoji: nil, systemRaw: category.rawValue)
    }

    static func custom(id: String, name: String, emoji: String) -> ExpenseCategory {
        ExpenseCategory(id: id, name: name, kind: .custom, emoji: emoji, systemRaw: nil)
    }

    var displayName: String {
        switch kind {
        case .system:
            if let raw = systemRaw, let category = Category(rawValue: raw) {
                return category.displayName
            }
            return name
        case .custom:
            return name
        }
    }

    var color: Color {
        switch kind {
        case .system:
            if let raw = systemRaw, let category = Category(rawValue: raw) {
                return category.color
            }
            return .gray
        case .custom:
            return Self.palette[abs(id.hashValue) % Self.palette.count]
        }
    }

    var iconName: String? {
        guard kind == .system, let raw = systemRaw, let category = Category(rawValue: raw) else {
            return nil
        }
        return category.iconName
    }

    private static let palette: [Color] = [
        .blue, .green, .orange, .pink, .purple, .teal, .indigo, .red, .mint, .cyan
    ]
}

struct CategoryProvider {
    static func systemCategories() -> [ExpenseCategory] {
        Category.allCases.map { ExpenseCategory.system($0) }
    }
}
