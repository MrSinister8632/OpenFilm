import SwiftUI
import SwiftData

struct RecipesTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var allRecipes: [Recipe]

    @State private var showImportSheet = false
    @State private var importCode = ""
    @State private var importError: String?
    @State private var importSuccess: String?
    @State private var recipeToDelete: Recipe?
    @State private var recipeToRename: Recipe?
    @State private var renameText = ""
    @State private var searchText = ""

    private var builtInRecipes: [Recipe] {
        allRecipes.filter { $0.isBuiltIn }
    }
    private var myRecipes: [Recipe] {
        let custom = allRecipes.filter { !$0.isBuiltIn }
        if searchText.isEmpty { return custom }
        return custom.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                builtInSection
                myRecipesSection
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search my recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showImportSheet = true
                    } label: {
                        Label("Import", systemImage: "arrow.down.doc")
                    }
                }
            }
            .sheet(isPresented: $showImportSheet) {
                ImportRecipeSheet(
                    isPresented: $showImportSheet,
                    onImport: handleImport
                )
            }
            .alert("Rename Recipe", isPresented: .constant(recipeToRename != nil)) {
                TextField("Name", text: $renameText)
                Button("Save") {
                    recipeToRename?.name = renameText
                    recipeToRename = nil
                }
                Button("Cancel", role: .cancel) { recipeToRename = nil }
            }
            .alert("Import Error", isPresented: .constant(importError != nil)) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .alert("Recipe Imported", isPresented: .constant(importSuccess != nil)) {
                Button("OK") { importSuccess = nil }
            } message: {
                Text(importSuccess ?? "")
            }
            .onAppear(perform: seedBuiltInsIfNeeded)
        }
    }

    // MARK: - Sections

    private var builtInSection: some View {
        Section("Built-In Recipes") {
            ForEach(builtInRecipes) { recipe in
                RecipeRow(recipe: recipe, showActions: false)
            }
        }
    }

    private var myRecipesSection: some View {
        Section {
            if myRecipes.isEmpty {
                Text(searchText.isEmpty ? "No custom recipes yet. Create one in the Create tab." : "No results.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(myRecipes) { recipe in
                    RecipeRow(recipe: recipe, showActions: true)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                modelContext.delete(recipe)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                recipeToRename = recipe
                                renameText = recipe.name
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                duplicateRecipe(recipe)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            recipeContextMenu(recipe)
                        }
                }
            }
        } header: {
            Text("My Recipes")
        }
    }

    @ViewBuilder
    private func recipeContextMenu(_ recipe: Recipe) -> some View {
        Button {
            recipeToRename = recipe
            renameText = recipe.name
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        Button {
            duplicateRecipe(recipe)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        Button {
            shareRecipe(recipe)
        } label: {
            Label("Share Code", systemImage: "square.and.arrow.up")
        }
        Divider()
        Button(role: .destructive) {
            modelContext.delete(recipe)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func handleImport(_ code: String) {
        do {
            let recipe = try ShareCodeCoder.decode(code: code)
            modelContext.insert(recipe)
            importSuccess = "\"\(recipe.name)\" has been added to My Recipes."
        } catch {
            importError = error.localizedDescription
        }
    }

    private func duplicateRecipe(_ recipe: Recipe) {
        let copy = recipe.duplicate(named: "\(recipe.name) Copy")
        modelContext.insert(copy)
    }

    private func shareRecipe(_ recipe: Recipe) {
        guard let code = try? ShareCodeCoder.encode(recipe: recipe) else { return }
        let av = UIActivityViewController(activityItems: [code], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }

    private func seedBuiltInsIfNeeded() {
        let existing = allRecipes.filter { $0.isBuiltIn }.map { $0.id }
        for recipe in BuiltInRecipes.all() {
            if !existing.contains(recipe.id) {
                modelContext.insert(recipe)
            }
        }
    }
}

// MARK: - RecipeRow

struct RecipeRow: View {
    let recipe: Recipe
    let showActions: Bool

    var body: some View {
        HStack(spacing: 12) {
            RecipeSwatch(recipe: recipe)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(.body.weight(.medium))
                Text(recipe.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(RecipeFingerprint.generate(for: recipe))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - RecipeSwatch (colour preview)

struct RecipeSwatch: View {
    let recipe: Recipe

    var body: some View {
        ZStack {
            // Warm/cool tint
            LinearGradient(
                colors: swatchColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Saturation overlay
            if recipe.saturation < -0.5 {
                Color.white.opacity(0.3).blendMode(.saturation)
            }
            // Grain texture hint
            if recipe.grainAmount > 0.1 {
                Rectangle()
                    .fill(.white.opacity(0.05))
            }
        }
    }

    private var swatchColors: [Color] {
        let warm = recipe.temperature > 0
        let base = warm
            ? Color(hue: 0.08, saturation: 0.5, brightness: 0.85)
            : Color(hue: 0.58, saturation: 0.3, brightness: 0.85)
        let mid  = Color(hue: 0.0, saturation: max(0, recipe.saturation + 0.5) * 0.4, brightness: 0.7)
        return [base, mid]
    }
}

// MARK: - Recipe shortDescription helper

extension Recipe {
    var shortDescription: String {
        var parts: [String] = []
        if saturation < -0.5 { parts.append("B&W") }
        else if saturation < -0.2 { parts.append("Muted") }
        else if saturation > 0.3  { parts.append("Vivid") }

        if temperature > 100       { parts.append("Warm") }
        else if temperature < -100 { parts.append("Cool") }

        if grainAmount > 0.1       { parts.append("Grain") }
        if vignetteAmount > 0.15   { parts.append("Vignette") }
        return parts.isEmpty ? "Neutral" : parts.joined(separator: " · ")
    }
}
