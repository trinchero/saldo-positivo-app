import Foundation
import AppIntents
import SwiftUI

enum Category: String, CaseIterable, Codable, AppEnum {
    case food
    case eatingOut
    case rent
    case shopping
    case entertainment
    case transportation
    case utilities
    case subscriptions
    case healthcare
    case education
    case others

    var displayName: String {
        switch self {
        case .food: return NSLocalizedString("Food", comment: "Category")
        case .eatingOut: return NSLocalizedString("Eating Out", comment: "Category")
        case .rent: return NSLocalizedString("Rent", comment: "Category")
        case .shopping: return NSLocalizedString("Shopping", comment: "Category")
        case .entertainment: return NSLocalizedString("Entertainment", comment: "Category")
        case .transportation: return NSLocalizedString("Transportation", comment: "Category")
        case .utilities: return NSLocalizedString("Utilities", comment: "Category")
        case .subscriptions: return NSLocalizedString("Subscriptions", comment: "Category")
        case .healthcare: return NSLocalizedString("Healthcare", comment: "Category")
        case .education: return NSLocalizedString("Education", comment: "Category")
        case .others: return NSLocalizedString("Others", comment: "Category")
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: LocalizedStringResource("Category"))

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .food: DisplayRepresentation(title: LocalizedStringResource("Food")),
        .eatingOut: DisplayRepresentation(title: LocalizedStringResource("Eating Out")),
        .rent: DisplayRepresentation(title: LocalizedStringResource("Rent")),
        .shopping: DisplayRepresentation(title: LocalizedStringResource("Shopping")),
        .entertainment: DisplayRepresentation(title: LocalizedStringResource("Entertainment")),
        .transportation: DisplayRepresentation(title: LocalizedStringResource("Transportation")),
        .utilities: DisplayRepresentation(title: LocalizedStringResource("Utilities")),
        .subscriptions: DisplayRepresentation(title: LocalizedStringResource("Subscriptions")),
        .healthcare: DisplayRepresentation(title: LocalizedStringResource("Healthcare")),
        .education: DisplayRepresentation(title: LocalizedStringResource("Education")),
        .others: DisplayRepresentation(title: LocalizedStringResource("Others"))
    ]
}

extension Category {
    var color: Color {
        switch self {
        case .food:
            return .green
        case .eatingOut:
            return .mint
        case .rent:
            return .purple
        case .shopping:
            return .orange
        case .entertainment:
            return .pink
        case .transportation:
            return .blue
        case .utilities:
            return .yellow
        case .subscriptions:
            return .teal
        case .healthcare:
            return .red
        case .education:
            return .indigo
        case .others:
            return .gray
        }
    }

    var iconName: String {
        switch self {
        case .food:
            return "cart.fill"
        case .eatingOut:
            return "fork.knife"
        case .rent:
            return "house.fill"
        case .shopping:
            return "bag.fill"
        case .entertainment:
            return "tv.fill"
        case .transportation:
            return "car.fill"
        case .utilities:
            return "bolt.fill"
        case .subscriptions:
            return "repeat"
        case .healthcare:
            return "heart.fill"
        case .education:
            return "book.fill"
        case .others:
            return "ellipsis"
        }
    }
}
