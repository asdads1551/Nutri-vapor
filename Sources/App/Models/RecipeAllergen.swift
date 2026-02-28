import Fluent
import Vapor

final class RecipeAllergen: Model, Content, @unchecked Sendable {
    static let schema = "recipe_allergens"

    @ID(key: .id) var id: UUID?
    @Parent(key: "recipe_id") var recipe: Recipe
    @Field(key: "allergen") var allergen: String

    init() {}

    init(id: UUID? = nil, recipeID: UUID, allergen: String) {
        self.id = id
        self.$recipe.id = recipeID
        self.allergen = allergen
    }
}
