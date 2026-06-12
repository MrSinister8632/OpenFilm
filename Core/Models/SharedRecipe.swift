import Foundation

struct SharedRecipe: Codable {

    let version: Int

    let name: String

    let author: String?

    let fingerprint: String

    let recipe: RecipePayload
}