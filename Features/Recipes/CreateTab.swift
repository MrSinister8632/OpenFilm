import SwiftUI
import SwiftData

struct CreateTab: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name          = "My Recipe"
    @State private var exposure      = 0.0
    @State private var contrast      = 0.0
    @State private var highlights    = 0.0
    @State private var shadows       = 0.0
    @State private var saturation    = 0.0
    @State private var temperature   = 0.0
    @State private var tint          = 0.0
    @State private var grainAmount   = 0.0
    @State private var vignetteAmount = 0.0
    @State private var sharpness     = 0.5

    @State private var showSaveAlert   = false
    @State private var savedMessage: String?
    @State private var showShareSheet  = false
    @State private var shareCode: String?
    @State private var isEditingName   = false

    private var currentRecipe: Recipe {
        let r = Recipe(name: name)
        r.exposure = exposure;   r.contrast = contrast
        r.highlights = highlights; r.shadows = shadows
        r.saturation = saturation; r.temperature = temperature
        r.tint = tint;           r.grainAmount = grainAmount
        r.vignetteAmount = vignetteAmount; r.sharpness = sharpness
        return r
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                toneSection
                colorSection
                effectsSection
                actionsSection
            }
            .navigationTitle("Create Recipe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveRecipe)
                        .font(.headline)
                }
            }
            .alert("Recipe Saved", isPresented: .constant(savedMessage != nil)) {
                Button("OK") { savedMessage = nil }
            } message: {
                Text(savedMessage ?? "")
            }
            .sheet(isPresented: .constant(shareCode != nil)) {
                if let code = shareCode {
                    ShareCodeView(code: code, recipe: currentRecipe) {
                        shareCode = nil
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Recipe Name") {
            HStack {
                TextField("Name", text: $name)
                    .font(.body.weight(.medium))
                Spacer()
                Text(RecipeFingerprint.generate(for: currentRecipe))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var toneSection: some View {
        Section("Tone") {
            FormSlider(label: "Exposure",   value: $exposure,    range: -2...2,     format: "%.2f")
            FormSlider(label: "Contrast",   value: $contrast,    range: -1...1,     format: "%.2f")
            FormSlider(label: "Highlights", value: $highlights,  range: -1...1,     format: "%.2f")
            FormSlider(label: "Shadows",    value: $shadows,     range: -1...1,     format: "%.2f")
        }
    }

    private var colorSection: some View {
        Section("Color") {
            FormSlider(label: "Saturation",  value: $saturation,  range: -1...1,     format: "%.2f")
            FormSlider(label: "Temperature", value: $temperature, range: -400...400, format: "%.0f")
            FormSlider(label: "Tint",        value: $tint,        range: -10...10,   format: "%.1f")
        }
    }

    private var effectsSection: some View {
        Section("Effects") {
            FormSlider(label: "Grain",     value: $grainAmount,    range: 0...1, format: "%.2f")
            FormSlider(label: "Vignette",  value: $vignetteAmount, range: 0...1, format: "%.2f")
            FormSlider(label: "Sharpness", value: $sharpness,      range: 0...1, format: "%.2f")
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                shareRecipe()
            } label: {
                Label("Share Recipe Code", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                resetAll()
            } label: {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
            }
        }
    }

    // MARK: - Actions

    private func saveRecipe() {
        let recipe = currentRecipe
        modelContext.insert(recipe)
        savedMessage = "\"\(recipe.name)\" has been added to My Recipes."
    }

    private func shareRecipe() {
        if let code = try? ShareCodeCoder.encode(recipe: currentRecipe) {
            shareCode = code
        }
    }

    private func resetAll() {
        exposure = 0; contrast = 0; highlights = 0; shadows = 0
        saturation = 0; temperature = 0; tint = 0
        grainAmount = 0; vignetteAmount = 0; sharpness = 0.5
    }
}

// MARK: - FormSlider

struct FormSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: format, value))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .trailing)
            }
            Slider(value: $value, in: range)
        }
        .padding(.vertical, 4)
    }
}
