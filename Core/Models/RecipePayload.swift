import Foundation

struct RecipePayload: Codable {

    let version: Int

    let exposure: Double
    let contrast: Double
    let highlights: Double
    let shadows: Double

    let saturation: Double
    let temperature: Double
    let tint: Double

    let grainAmount: Double
    let vignetteAmount: Double
    let sharpness: Double
}