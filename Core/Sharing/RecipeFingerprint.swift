import Foundation
import CryptoKit

enum RecipeFingerprint {

    static func generate(
        for recipe: RecipePayload
    ) -> String {

        let canonical = canonicalString(
            from: recipe
        )

        let digest = SHA256.hash(
            data: Data(canonical.utf8)
        )

        let hex = digest
            .compactMap {
                String(format: "%02X", $0)
            }
            .joined()

        let short = String(
            hex.prefix(8)
        )

        return "\(short.prefix(4))-\(short.suffix(4))"
    }

    private static func canonicalString(
        from recipe: RecipePayload
    ) -> String {

        [
            "contrast=\(format(recipe.contrast))",
            "exposure=\(format(recipe.exposure))",
            "grain=\(format(recipe.grainAmount))",
            "highlights=\(format(recipe.highlights))",
            "saturation=\(format(recipe.saturation))",
            "shadows=\(format(recipe.shadows))",
            "sharpness=\(format(recipe.sharpness))",
            "temperature=\(format(recipe.temperature))",
            "tint=\(format(recipe.tint))",
            "vignette=\(format(recipe.vignetteAmount))"
        ]
        .joined(separator: "|")
    }

    private static func format(
        _ value: Double
    ) -> String {
        String(format: "%.4f", value)
    }
}