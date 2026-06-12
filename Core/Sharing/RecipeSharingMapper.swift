import Foundation

enum RecipeSharingMapper {

    // MARK: - RecipeEntity -> RecipePayload

    static func toPayload(
        _ recipe: RecipeEntity
    ) -> RecipePayload {

        RecipePayload(
            version: 1,
            exposure: recipe.exposure,
            contrast: recipe.contrast,
            highlights: recipe.highlights,
            shadows: recipe.shadows,
            saturation: recipe.saturation,
            temperature: recipe.temperature,
            tint: recipe.tint,
            grainAmount: recipe.grainAmount,
            vignetteAmount: recipe.vignetteAmount,
            sharpness: recipe.sharpness
        )
    }

    // MARK: - RecipeEntity -> SharedRecipe

    static func toSharedRecipe(
        _ recipe: RecipeEntity,
        author: String? = nil
    ) -> SharedRecipe {

        let payload = toPayload(recipe)

        return SharedRecipe(
            version: 1,
            name: recipe.name,
            author: author,
            fingerprint: RecipeFingerprint.generate(
                for: payload
            ),
            recipe: payload
        )
    }

    // MARK: - SharedRecipe -> RecipeEntity

    static func toRecipeEntity(
        _ sharedRecipe: SharedRecipe,
        source: RecipeSource = .imported
    ) -> RecipeEntity {

        let payload = sharedRecipe.recipe

        return RecipeEntity(
            name: sharedRecipe.name,
            source: source,
            exposure: payload.exposure,
            contrast: payload.contrast,
            highlights: payload.highlights,
            shadows: payload.shadows,
            saturation: payload.saturation,
            temperature: payload.temperature,
            tint: payload.tint,
            grainAmount: payload.grainAmount,
            vignetteAmount: payload.vignetteAmount,
            sharpness: payload.sharpness
        )
    }
}