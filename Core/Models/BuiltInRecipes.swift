import Foundation

/// Factory for the six built-in OpenFilm recipes.
/// These are OpenFilm implementations — not official recreations of any
/// manufacturer's film simulations.
enum BuiltInRecipes {

    static func all() -> [Recipe] {
        [neutral, classicChrome, warmVintage, cinematic, vibrantLandscape, monochrome]
    }

    // MARK: - Neutral
    static let neutral = Recipe(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Neutral",
        isBuiltIn: true,
        exposure: 0,
        contrast: 0,
        highlights: 0,
        shadows: 0,
        saturation: 0,
        temperature: 0,
        tint: 0,
        grainAmount: 0,
        vignetteAmount: 0,
        sharpness: 0.5
    )

    // MARK: - Classic Chrome Inspired
    // Muted colors and contrast
    static let classicChrome = Recipe(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Classic Chrome",
        isBuiltIn: true,
        exposure: -0.1,
        contrast: -0.15,
        highlights: -0.3,
        shadows: 0.1,
        saturation: -0.4,
        temperature: -50,
        tint: 2,
        grainAmount: 0.05,
        vignetteAmount: 0.1,
        sharpness: 0.4
    )

    // MARK: - Warm Vintage
    // Warm tones and soft contrast
    static let warmVintage = Recipe(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Warm Vintage",
        isBuiltIn: true,
        exposure: 0.05,
        contrast: -0.1,
        highlights: -0.2,
        shadows: 0.2,
        saturation: -0.1,
        temperature: 180,
        tint: 5,
        grainAmount: 0.15,
        vignetteAmount: 0.2,
        sharpness: 0.3
    )

    // MARK: - Cinematic
    // Reduced saturation and lifted shadows
    static let cinematic = Recipe(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Cinematic",
        isBuiltIn: true,
        exposure: -0.05,
        contrast: 0.1,
        highlights: -0.3,
        shadows: 0.3,
        saturation: -0.3,
        temperature: -30,
        tint: 0,
        grainAmount: 0.08,
        vignetteAmount: 0.25,
        sharpness: 0.45
    )

    // MARK: - Vibrant Landscape
    // High saturation and punchier contrast
    static let vibrantLandscape = Recipe(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "Vibrant Landscape",
        isBuiltIn: true,
        exposure: 0.05,
        contrast: 0.2,
        highlights: -0.1,
        shadows: 0.05,
        saturation: 0.5,
        temperature: 20,
        tint: -2,
        grainAmount: 0,
        vignetteAmount: 0.1,
        sharpness: 0.7
    )

    // MARK: - Monochrome
    // Black and white
    static let monochrome = Recipe(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        name: "Monochrome",
        isBuiltIn: true,
        exposure: 0,
        contrast: 0.15,
        highlights: -0.1,
        shadows: 0.05,
        saturation: -1.0,
        temperature: 0,
        tint: 0,
        grainAmount: 0.1,
        vignetteAmount: 0.15,
        sharpness: 0.6
    )
}
