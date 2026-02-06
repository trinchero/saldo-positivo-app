import SwiftUI

struct CategoryGrid: View {
    let categories: [ExpenseCategory]
    @Binding var selectedCategory: ExpenseCategory
    var onCategorySelected: (() -> Void)? = nil
    
    // Number of columns in the grid
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(categories, id: \.id) { category in
                CategoryButton(
                    category: category,
                    isSelected: selectedCategory == category,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                        onCategorySelected?()
                    }
                )
            }
        }
        .padding(.vertical, 10)
    }
}

// An alternative version with a manual callback for cases where binding isn't appropriate
struct CategoryGridWithCallback: View {
    let categories: [ExpenseCategory]
    let selectedCategory: ExpenseCategory
    let onCategorySelected: (ExpenseCategory) -> Void
    
    // Number of columns in the grid
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(categories, id: \.id) { category in
                CategoryButton(
                    category: category,
                    isSelected: selectedCategory == category,
                    action: {
                        onCategorySelected(category)
                    }
                )
            }
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    VStack {
        Text("Category Grid Preview")
            .font(.headline)
            .padding()
        
        CategoryGrid(
            categories: CategoryProvider.systemCategories(),
            selectedCategory: .constant(.system(.food))
        )
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding()
    }
} 
