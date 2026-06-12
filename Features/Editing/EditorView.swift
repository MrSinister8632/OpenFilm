import SwiftUI
import SwiftData

struct EditorView: View {
    let sourceImage: CIImage
    let sourcePhotoID: String
    let onSave: (EditSession) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var allRecipes: [Recipe]

    @State private var activeRecipe: Recipe
    @State private var showRecipePicker = false
    @State private var showExport = false
    @State private var showShare = false
    @State private var shareCode: String?
    @State private var renderedImage: UIImage?
    @State private var isRendering = false

    // Transient editable copy of the recipe values
    @State private var exposure: Double
    @State private var contrast: Double
    @State private var highlights: Double
    @State private var shadows: Double
    @State private var saturation: Double
    @State private var temperature: Double
    @State private var tint: Double
    @State private var grainAmount: Double
    @State private var vignetteAmount: Double
    @State private var sharpness: Double

    init(sourceImage: CIImage, sourcePhotoID: String, onSave: @escaping (EditSession) -> Void) {
        self.sourceImage   = sourceImage
        self.sourcePhotoID = sourcePhotoID
        self.onSave        = onSave

        let neutral = BuiltInRecipes.neutral
        _activeRecipe    = State(initialValue: neutral)
        _exposure        = State(initialValue: neutral.exposure)
        _contrast        = State(initialValue: neutral.contrast)
        _highlights      = State(initialValue: neutral.highlights)
        _shadows         = State(initialValue: neutral.shadows)
        _saturation      = State(initialValue: neutral.saturation)
        _temperature     = State(initialValue: neutral.temperature)
        _tint            = State(initialValue: neutral.tint)
        _grainAmount     = State(initialValue: neutral.grainAmount)
        _vignetteAmount  = State(initialValue: neutral.vignetteAmount)
        _sharpness       = State(initialValue: neutral.sharpness)
    }

    private var currentRecipe: Recipe {
        let r = Recipe(name: activeRecipe.name)
        r.exposure = exposure;   r.contrast = contrast
        r.highlights = highlights; r.shadows = shadows
        r.saturation = saturation; r.temperature = temperature
        r.tint = tint;           r.grainAmount = grainAmount
        r.vignetteAmount = vignetteAmount; r.sharpness = sharpness
        return r
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview
                previewArea
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.48)

                Divider()

                // Controls
                controlsArea
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showRecipePicker) {
                RecipePickerSheet(recipes: allRecipes) { selected in
                    applyRecipe(selected)
                }
            }
            .sheet(isPresented: $showExport) {
                ExportView(sourceImage: sourceImage, recipe: currentRecipe)
            }
            .sheet(isPresented: .constant(shareCode != nil)) {
                if let code = shareCode {
                    ShareCodeView(code: code, recipe: currentRecipe) {
                        shareCode = nil
                    }
                }
            }
        }
        .onAppear { renderPreview() }
    }

    // MARK: - Preview

    private var previewArea: some View {
        ZStack {
            Color.black

            if let img = renderedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            } else {
                ProgressView()
                    .tint(.white)
            }

            if isRendering {
                ProgressView()
                    .tint(.white)
                    .padding(12)
                    .background(.black.opacity(0.5))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Controls

    private var controlsArea: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Recipe selector bar
                recipeBar
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                Divider()

                // Sliders
                VStack(spacing: 4) {
                    SliderRow(label: "Exposure",    value: $exposure,       range: -2...2,     format: "%.2f") { renderPreview() }
                    SliderRow(label: "Contrast",    value: $contrast,       range: -1...1,     format: "%.2f") { renderPreview() }
                    SliderRow(label: "Highlights",  value: $highlights,     range: -1...1,     format: "%.2f") { renderPreview() }
                    SliderRow(label: "Shadows",     value: $shadows,        range: -1...1,     format: "%.2f") { renderPreview() }
                    SliderRow(label: "Saturation",  value: $saturation,     range: -1...1,     format: "%.2f") { renderPreview() }
                    SliderRow(label: "Temperature", value: $temperature,    range: -400...400, format: "%.0f") { renderPreview() }
                    SliderRow(label: "Tint",        value: $tint,           range: -10...10,   format: "%.1f") { renderPreview() }
                    SliderRow(label: "Grain",       value: $grainAmount,    range: 0...1,      format: "%.2f") { renderPreview() }
                    SliderRow(label: "Vignette",    value: $vignetteAmount, range: 0...1,      format: "%.2f") { renderPreview() }
                    SliderRow(label: "Sharpness",   value: $sharpness,      range: 0...1,      format: "%.2f") { renderPreview() }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
    }

    private var recipeBar: some View {
        HStack {
            Button {
                showRecipePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                    Text(activeRecipe.name)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(RecipeFingerprint.generate(for: currentRecipe))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    if let code = try? ShareCodeCoder.encode(recipe: currentRecipe) {
                        shareCode = code
                    }
                } label: {
                    Label("Share Recipe Code", systemImage: "square.and.arrow.up")
                }
                Button {
                    showExport = true
                } label: {
                    Label("Export Image", systemImage: "arrow.down.to.line")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { saveSession() }
        }
    }

    // MARK: - Actions

    private func applyRecipe(_ recipe: Recipe) {
        activeRecipe   = recipe
        exposure       = recipe.exposure
        contrast       = recipe.contrast
        highlights     = recipe.highlights
        shadows        = recipe.shadows
        saturation     = recipe.saturation
        temperature    = recipe.temperature
        tint           = recipe.tint
        grainAmount    = recipe.grainAmount
        vignetteAmount = recipe.vignetteAmount
        sharpness      = recipe.sharpness
        renderPreview()
    }

    private func renderPreview() {
        isRendering = true
        let recipe = currentRecipe
        let image  = sourceImage
        Task.detached(priority: .userInitiated) {
            let result = ImageProcessor.shared.render(
                image: image,
                recipe: recipe,
                maxDimension: 1024
            )
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.15)) {
                    renderedImage = result
                }
                isRendering = false
            }
        }
    }

    private func saveSession() {
        let session = EditSession(sourcePhotoID: sourcePhotoID, recipe: currentRecipe)
        // Cache thumbnail
        if let thumb = ImageProcessor.shared.render(
            image: sourceImage, recipe: currentRecipe, maxDimension: 256
        ) {
            session.thumbnailData = thumb.jpegData(compressionQuality: 0.7)
        }
        onSave(session)
        dismiss()
    }
}

// MARK: - SliderRow

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    let onEditEnd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .leading)

            Slider(value: $value, in: range) { editing in
                if !editing { onEditEnd() }
            }

            Text(String(format: format, value))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
