import Foundation

struct Expense: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var price: Double
    var date: Date
    var category: ExpenseCategory

    enum CodingKeys: String, CodingKey {
        case id, title, price, date, category
    }

    init(id: UUID = UUID(), title: String, price: Double, date: Date, category: ExpenseCategory) {
        self.id = id
        self.title = title
        self.price = price
        self.date = date
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        price = try container.decode(Double.self, forKey: .price)
        date = try container.decode(Date.self, forKey: .date)

        if let decodedCategory = try? container.decode(ExpenseCategory.self, forKey: .category) {
            category = decodedCategory
        } else {
            // Backward-compatible decode (old data stored raw category string)
            let legacyRaw = try container.decode(String.self, forKey: .category)
            let legacy = Category(rawValue: legacyRaw) ?? .others
            category = ExpenseCategory.system(legacy)
        }
    }
}
