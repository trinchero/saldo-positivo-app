import Foundation
import SwiftUI
import Combine

@MainActor
class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadExpenses()
        NotificationCenter.default.publisher(for: .dataReset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.expenses = []
            }
            .store(in: &cancellables)
    }
    
    func addExpense(title: String, price: Double, date: Date, category: ExpenseCategory) -> Expense {
        let newExpense = Expense(title: title, price: price, date: date, category: category)
        expenses.append(newExpense)
        saveExpenses()
        return newExpense
    }
    
    func deleteExpense(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        saveExpenses()
    }
    
    func saveExpenses() {
        StorageService.saveExpenses(expenses)
    }

    func loadExpenses() {
        expenses = StorageService.loadExpenses()
    }
    
    func deleteExpenses(_ expenses: [Expense]) {
        for expense in expenses {
            if let index = self.expenses.firstIndex(where: { $0.id == expense.id }) {
                self.expenses.remove(at: index)
            }
        }
        saveExpenses()
    }

}
