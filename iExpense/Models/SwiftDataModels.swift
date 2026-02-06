import Foundation
import SwiftData

// MARK: - Models for SwiftData

// This file contains the models needed for SwiftData
// These are completely separate from the current app functionality
// and will be gradually integrated

@Model
final class ExpenseItem {
    var id: String
    var name: String
    var amount: Double
    var date: Date
    var categoryName: String
    var notes: String?
    
    init(id: String = UUID().uuidString, 
         name: String, 
         amount: Double, 
         date: Date, 
         categoryName: String, 
         notes: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.date = date
        self.categoryName = categoryName
        self.notes = notes
    }
}

@Model
final class BudgetItem {
    @Attribute(.unique) var monthYear: String // Format: "MM-yyyy"
    var amount: Double
    
    init(monthYear: String, amount: Double) {
        self.monthYear = monthYear
        self.amount = amount
    }
    
    // Helper to create a monthYear string from Date
    static func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-yyyy"
        return formatter.string(from: date)
    }
}

@Model
final class CustomCategoryItem {
    @Attribute(.unique) var id: String
    var name: String
    var emoji: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         emoji: String,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
