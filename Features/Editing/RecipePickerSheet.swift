import SwiftUI

struct RecipePickerSheet: View {
    let recipes: [Recipe]
    let onSelect: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss

    private var builtIns: [Recipe] { recipes.filter { $0.isBuiltIn } }
    private var custom:   [Recipe] { recipes.filter { !$0.isBuiltIn } }

    var body: some View {
        NavigationStack {
            List {
                Section("Built-In") {
                    ForEach(builtIns) { recipe in
                        recipeRow(recipe)
                    }
                }
                if !custom.isEmpty {
                    Section("My Recipes") {
                        ForEach(custom) { recipe in
                            recipeRow(recipe)
                        }
                    }
                }
            }
            .navigationTitle("Choose Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        Button {
            onSelect(recipe)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                RecipeSwatch(recipe: recipe)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(recipe.shortDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
