import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var name: String
    var isBuiltIn: Bool

    // Tone
    var exposure: Double      // -2.0 to +2.0
    var contrast: Double      // -1.0 to +1.0
    var highlights: Double    // -1.0 to +1.0
    var shadows: Double       // -1.0 to +1.0

    // Color
    var saturation: Double    // -1.0 to +1.0
    var temperature: Double   // -400 to +400 (Kelvin shift)
    var tint: Double          // -1.0 to +1.0

    // Effects
    var grainAmount: Double   // 0.0 to 1.0
    var vignetteAmount: Double // 0.0 to 1.0
    var sharpness: Double     // 0.0 to 1.0

    init(
        id: UUID = UUID(),
        name: String,
        isBuiltIn: Bool = false,
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
        self.isBuiltIn = isBuiltIn
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

    func duplicate(named newName: String) -> Recipe {
        Recipe(
            name: newName,
            isBuiltIn: false,
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

// MARK: - Canonical representation for fingerprinting / sharing

extension Recipe {
    /// Produces a deterministic sorted key=value string for hashing.
    var canonicalString: String {
        let parts: [(String, String)] = [
            ("contrast",    String(format: "%.4f", contrast)),
            ("exposure",    String(format: "%.4f", exposure)),
            ("grain",       String(format: "%.4f", grainAmount)),
            ("highlights",  String(format: "%.4f", highlights)),
            ("name",        name),
            ("saturation",  String(format: "%.4f", saturation)),
            ("shadows",     String(format: "%.4f", shadows)),
            ("sharpness",   String(format: "%.4f", sharpness)),
            ("temperature", String(format: "%.4f", temperature)),
            ("tint",        String(format: "%.4f", tint)),
            ("vignette",    String(format: "%.4f", vignetteAmount)),
        ]
        return parts.map { "\($0.0)=\($0.1)" }.joined(separator: "|")
    }
}
