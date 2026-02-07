import SwiftUI
import SwiftData

struct CategoriesSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategoryItem.createdAt, order: .forward) private var customCategories: [CustomCategoryItem]

    @State private var showingEditor = false
    @State private var editingCategory: CustomCategoryItem? = nil
    @State private var editorName: String = ""
    @State private var editorEmoji: String = ""

    private let minTotalCategories = 9
    private let maxTotalCategories = 15

    private var maxCustomCategories: Int {
        max(0, maxTotalCategories - Category.allCases.count)
    }

    private var totalCategoriesCount: Int {
        Category.allCases.count + customCategories.count
    }

    private var canAddCustom: Bool {
        customCategories.count < maxCustomCategories
    }

    private var canDeleteCustom: Bool {
        totalCategoriesCount > minTotalCategories
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(NSLocalizedString("Default Categories", comment: "Default categories section"))) {
                    ForEach(Category.allCases, id: \.self) { category in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 28, height: 28)
                                Image(systemName: category.iconName)
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            Text(category.displayName)
                            Spacer()
                            Text(NSLocalizedString("Default", comment: "Default label"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text(NSLocalizedString("Custom Categories", comment: "Custom categories section")), footer: footerText) {
                    if customCategories.isEmpty {
                        Text(NSLocalizedString("No custom categories yet", comment: "Empty custom categories"))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(customCategories) { category in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 28, height: 28)
                                    Text(category.emoji)
                                        .font(.caption)
                                }
                                Text(category.name)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    startEdit(category)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)

                                Button(role: .destructive) {
                                    deleteCategory(category)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .disabled(!canDeleteCustom)
                            }
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Categories", comment: "Categories title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Done", comment: "Done")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Add", comment: "Add")) {
                        startAdd()
                    }
                    .disabled(!canAddCustom)
                }
            }
            .sheet(isPresented: $showingEditor) {
                NavigationView {
                    Form {
                        Section(header: Text(NSLocalizedString("Category Details", comment: "Category details"))) {
                            TextField(NSLocalizedString("Name", comment: "Name"), text: $editorName)
                            TextField(NSLocalizedString("Emoji", comment: "Emoji"), text: $editorEmoji)
                                .onChange(of: editorEmoji) { _, newValue in
                                    editorEmoji = normalizedEmoji(newValue)
                                }
                        }

                        if !canAddCustom && editingCategory == nil {
                            Section {
                                Text(String(format: NSLocalizedString("You can add up to %d custom categories.", comment: "Max custom categories"), maxCustomCategories))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .navigationTitle(editingCategory == nil ? NSLocalizedString("New Category", comment: "New category") : NSLocalizedString("Edit Category", comment: "Edit category"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(NSLocalizedString("Cancel", comment: "Cancel")) { closeEditor() }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("Save", comment: "Save")) { saveEditor() }
                                .disabled(editorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editorEmoji.isEmpty)
                        }
                    }
                }
            }
        }
    }

    private var footerText: some View {
        Text(String(format: NSLocalizedString("Max %d categories. Default categories cannot be removed.", comment: "Categories limit"), maxTotalCategories))
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func startAdd() {
        editingCategory = nil
        editorName = ""
        editorEmoji = ""
        showingEditor = true
    }

    private func startEdit(_ category: CustomCategoryItem) {
        editingCategory = category
        editorName = category.name
        editorEmoji = category.emoji
        showingEditor = true
    }

    private func closeEditor() {
        showingEditor = false
    }

    private func saveEditor() {
        let name = editorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = normalizedEmoji(editorEmoji)

        if let editingCategory {
            editingCategory.name = name
            editingCategory.emoji = emoji
            editingCategory.updatedAt = Date()
            updateExpensesForCustomCategory(id: editingCategory.id, name: name, emoji: emoji)
        } else {
            let newCategory = CustomCategoryItem(name: name, emoji: emoji)
            modelContext.insert(newCategory)
        }

        try? modelContext.save()
        closeEditor()
    }

    private func deleteCategory(_ category: CustomCategoryItem) {
        guard canDeleteCustom else { return }
        modelContext.delete(category)
        try? modelContext.save()
        reassignDeletedCategoryExpenses(categoryId: category.id)
    }

    private func normalizedEmoji(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "" }
        return String(first)
    }

    private func updateExpensesForCustomCategory(id: String, name: String, emoji: String) {
        var expenses = StorageService.loadExpenses()
        var changed = false
        for index in expenses.indices {
            let category = expenses[index].category
            if category.kind == .custom && category.id == id {
                expenses[index].category.name = name
                expenses[index].category.emoji = emoji
                changed = true
            }
        }
        if changed {
            StorageService.saveExpenses(expenses)
        }
    }

    private func reassignDeletedCategoryExpenses(categoryId: String) {
        var expenses = StorageService.loadExpenses()
        var changed = false
        for index in expenses.indices {
            let category = expenses[index].category
            if category.kind == .custom && category.id == categoryId {
                expenses[index].category = .system(.others)
                changed = true
            }
        }
        if changed {
            StorageService.saveExpenses(expenses)
        }
    }
}

#Preview {
    CategoriesSettingsView()
}
