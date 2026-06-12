import Foundation
import SwiftData

/// A non-destructive editing session linking a source photo to a recipe snapshot.
/// The original photo is never modified. Rendering happens on demand.
@Model
final class EditSession {
    var id: UUID
    var sourcePhotoID: String   // PHAsset localIdentifier
    var recipeName: String      // denormalised for display without fetching recipe

    // Recipe snapshot — persisted so edits survive recipe deletion/changes
    var snapshotExposure: Double
    var snapshotContrast: Double
    var snapshotHighlights: Double
    var snapshotShadows: Double
    var snapshotSaturation: Double
    var snapshotTemperature: Double
    var snapshotTint: Double
    var snapshotGrainAmount: Double
    var snapshotVignetteAmount: Double
    var snapshotSharpness: Double

    var createdAt: Date
    var modifiedAt: Date

    // Optional thumbnail cached after first render (JPEG data)
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    init(sourcePhotoID: String, recipe: Recipe) {
        self.id = UUID()
        self.sourcePhotoID = sourcePhotoID
        self.recipeName = recipe.name
        self.snapshotExposure = recipe.exposure
        self.snapshotContrast = recipe.contrast
        self.snapshotHighlights = recipe.highlights
        self.snapshotShadows = recipe.shadows
        self.snapshotSaturation = recipe.saturation
        self.snapshotTemperature = recipe.temperature
        self.snapshotTint = recipe.tint
        self.snapshotGrainAmount = recipe.grainAmount
        self.snapshotVignetteAmount = recipe.vignetteAmount
        self.snapshotSharpness = recipe.sharpness
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    /// Reconstructs a transient Recipe value from the snapshot fields.
    var recipeSnapshot: Recipe {
        Recipe(
            name: recipeName,
            exposure: snapshotExposure,
            contrast: snapshotContrast,
            highlights: snapshotHighlights,
            shadows: snapshotShadows,
            saturation: snapshotSaturation,
            temperature: snapshotTemperature,
            tint: snapshotTint,
            grainAmount: snapshotGrainAmount,
            vignetteAmount: snapshotVignetteAmount,
            sharpness: snapshotSharpness
        )
    }

    func applyRecipe(_ recipe: Recipe) {
        recipeName = recipe.name
        snapshotExposure = recipe.exposure
        snapshotContrast = recipe.contrast
        snapshotHighlights = recipe.highlights
        snapshotShadows = recipe.shadows
        snapshotSaturation = recipe.saturation
        snapshotTemperature = recipe.temperature
        snapshotTint = recipe.tint
        snapshotGrainAmount = recipe.grainAmount
        snapshotVignetteAmount = recipe.vignetteAmount
        snapshotSharpness = recipe.sharpness
        modifiedAt = Date()
        thumbnailData = nil // invalidate cached thumbnail
    }
}
