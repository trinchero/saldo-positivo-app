import Foundation

extension CategoryProvider {
    static func combinedCategories(custom: [CustomCategoryItem]) -> [ExpenseCategory] {
        let system = systemCategories()
        let customConverted = custom.map { ExpenseCategory.custom(id: $0.id, name: $0.name, emoji: $0.emoji) }
        return system + customConverted
    }
}
