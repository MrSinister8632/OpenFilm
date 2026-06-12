import Foundation
import SwiftData

@Model
final class RecipeEntity {

    let id: UUID

    var name: String
    var source: RecipeSource

    // Tone
    var exposure: Double
    var contrast: Double
    var highlights: Double
    var shadows: Double

    // Color
    var saturation: Double
    var temperature: Double
    var tint: Double

    // Effects
    var grainAmount: Double
    var vignetteAmount: Double
    var sharpness: Double

    init(
        id: UUID = UUID(),
        name: String,
        source: RecipeSource = .custom,
        exposure: Double = 0,
        contrast: Double = 0,
        highlights: Double = 0,
        shadows: Double = 0,
        saturation: Double = 0,
        temperature: Double = 0,
        tint: Double = 0,
        grainAmount: Double = 0,
        vignetteAmount: Double = 0,
        sharpness: Double = 0.5
    ) {
        self.id = id
        self.name = name
        self.source = source

        self.exposure = exposure
        self.contrast = contrast
        self.highlights = highlights
        self.shadows = shadows

        self.saturation = saturation
        self.temperature = temperature
        self.tint = tint

        self.grainAmount = grainAmount
        self.vignetteAmount = vignetteAmount
        self.sharpness = sharpness
    }

    func duplicate(named newName: String) -> RecipeEntity {
        RecipeEntity(
            name: newName,
            source: .custom,
            exposure: exposure,
            contrast: contrast,
            highlights: highlights,
            shadows: shadows,
            saturation: saturation,
            temperature: temperature,
            tint: tint,
            grainAmount: grainAmount,
            vignetteAmount: vignetteAmount,
            sharpness: sharpness
        )
    }

    func toPayload() -> RecipePayload {
        RecipePayload(
            version: 1,
            exposure: exposure,
            contrast: contrast,
            highlights: highlights,
            shadows: shadows,
            saturation: saturation,
            temperature: temperature,
            tint: tint,
            grainAmount: grainAmount,
            vignetteAmount: vignetteAmount,
            sharpness: sharpness
        )
    }
}