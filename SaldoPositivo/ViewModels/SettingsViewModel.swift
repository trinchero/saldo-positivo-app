import Foundation
import SwiftUI
import SwiftData

enum AppTheme: String, CaseIterable, Identifiable {
    case light, dark, system
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .light: return NSLocalizedString("Light", comment: "Light theme")
        case .dark: return NSLocalizedString("Dark", comment: "Dark theme")
        case .system: return NSLocalizedString("System", comment: "System theme")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case spanish
    case italian

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .english: return NSLocalizedString("English (Standard)", comment: "English language")
        case .spanish: return NSLocalizedString("Spanish", comment: "Spanish language")
        case .italian: return NSLocalizedString("Italian", comment: "Italian language")
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        case .italian: return "it"
        }
    }
}

// Available currencies with symbols - making this global to avoid actor isolation issues
let availableCurrencies: [(code: String, symbol: String, name: String)] = [
    ("USD", "$", "US Dollar"),
    ("EUR", "€", "Euro"),
    ("MDL", "L", "Moldovan Leu"),
    ("GBP", "£", "British Pound"),
    ("JPY", "¥", "Japanese Yen"),
    ("CAD", "$", "Canadian Dollar"),
    ("AUD", "$", "Australian Dollar"),
    ("CHF", "Fr", "Swiss Franc"),
    ("CNY", "¥", "Chinese Yuan"),
    ("INR", "₹", "Indian Rupee"),
    ("RUB", "₽", "Russian Ruble")
]

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedCurrency: String {
        didSet {
            // Save to standard UserDefaults
            UserDefaults.standard.set(selectedCurrency, forKey: "selectedCurrency")
            
            // Also save to shared app group UserDefaults for widget access
            let sharedDefaults = UserDefaults(suiteName: StorageService.appGroupID)
            sharedDefaults?.set(selectedCurrency, forKey: "selectedCurrency")
            sharedDefaults?.synchronize() // Force immediate write
        }
    }
    
    @Published var defaultCategory: Category {
        didSet {
            UserDefaults.standard.set(defaultCategory.rawValue, forKey: "defaultCategory")
        }
    }
    
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }

    @Published var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    @Published var exportFileName: String = "SaldoPositivo_export_\(Date().formatted(.dateTime.year().month().day()))"
    
    init() {
        // Get the shared UserDefaults for settings
        let sharedDefaults = UserDefaults(suiteName: StorageService.appGroupID)
        
        // Load currency setting - try shared first, then standard 
        if let savedCurrency = sharedDefaults?.string(forKey: "selectedCurrency") {
            self.selectedCurrency = savedCurrency
        } else if let savedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency") {
            self.selectedCurrency = savedCurrency
            
            // Sync this value to shared defaults
            sharedDefaults?.set(savedCurrency, forKey: "selectedCurrency")
            sharedDefaults?.synchronize()
        } else {
            self.selectedCurrency = "EUR"
            
            // Set default in both places
            UserDefaults.standard.set("EUR", forKey: "selectedCurrency")
            sharedDefaults?.set("EUR", forKey: "selectedCurrency")
            sharedDefaults?.synchronize()
        }
        
        let savedCategory = UserDefaults.standard.string(forKey: "defaultCategory")
        self.defaultCategory = Category(rawValue: savedCategory ?? "food") ?? .food
        
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme")
        self.selectedTheme = AppTheme(rawValue: savedTheme ?? "system") ?? .system

        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
        self.selectedLanguage = AppLanguage(rawValue: savedLanguage ?? "english") ?? .english
    }
    
    func exportData() -> URL? {
        let expenses = StorageService.loadExpenses()
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(expenses)
            
            let fileManager = FileManager.default
            let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            print("DEBUG: exported file \(exportFileName).json")
            let fileURL = documentDirectory.appendingPathComponent("\(exportFileName).json")
            
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func importData(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let expenses = try decoder.decode([Expense].self, from: data)
            
            StorageService.saveExpenses(expenses)
            return true
        } catch {
            return false
        }
    }
    
    func resetAllData(using context: ModelContext? = nil) {
        StorageService.saveExpenses([])
        StorageService.saveBudgets([:])

        // Clear stored notes and related UI state
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("notes_") {
            defaults.removeObject(forKey: key)
        }
        defaults.removeObject(forKey: "lastUsedCategoryKey")
        defaults.removeObject(forKey: "lastUsedCategory")
        defaults.removeObject(forKey: "swiftDataMigrationCompleted")

        if let sharedDefaults = UserDefaults(suiteName: StorageService.appGroupID) {
            for key in sharedDefaults.dictionaryRepresentation().keys where key.hasPrefix("notes_") {
                sharedDefaults.removeObject(forKey: key)
            }
            sharedDefaults.removeObject(forKey: "lastUsedCategoryKey")
            sharedDefaults.removeObject(forKey: "lastUsedCategory")
        }

        if let context = context {
            do {
                let expenseDescriptor = FetchDescriptor<ExpenseItem>()
                let budgetDescriptor = FetchDescriptor<BudgetItem>()
                let categoryDescriptor = FetchDescriptor<CustomCategoryItem>()

                let expenses = try context.fetch(expenseDescriptor)
                let budgets = try context.fetch(budgetDescriptor)
                let categories = try context.fetch(categoryDescriptor)

                for item in expenses { context.delete(item) }
                for item in budgets { context.delete(item) }
                for item in categories { context.delete(item) }

                try context.save()
            } catch {
                // Fail silently; reset of UserDefaults is still complete.
            }
        }

        NotificationCenter.default.post(name: .dataReset, object: nil)
    }
    
    // Static method to get app-wide settings without needing to initialize
    static func getAppCurrency() -> String {
        // First try to get from shared defaults
        let sharedDefaults = UserDefaults(suiteName: StorageService.appGroupID)
        
        if let sharedDefaults = sharedDefaults {
            // Force sync to make sure we have latest data
            sharedDefaults.synchronize()
            
            if let currency = sharedDefaults.string(forKey: "selectedCurrency") {
                return currency
            }
        }
        
        // Fall back to standard defaults
        return UserDefaults.standard.string(forKey: "selectedCurrency") ?? "EUR"
    }
}

// Function to get currency symbol - doesn't use main actor
func getSettingsCurrencySymbol() -> String {
    let code = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "EUR"
    if let currency = availableCurrencies.first(where: { $0.code == code }) {
        return currency.symbol
    }
    return "$" // Default fallback
}
