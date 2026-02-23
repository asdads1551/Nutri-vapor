import Fluent
import Vapor

final class RecipeTagModel: Model, Content, @unchecked Sendable {
    static let schema = "recipe_tags"

    @ID(key: .id) var id: UUID?
    @Parent(key: "recipe_id") var recipe: Recipe
    @Field(key: "tag") var tag: RecipeTagDB

    init() {}

    init(id: UUID? = nil, recipeID: UUID, tag: RecipeTagDB) {
        self.id = id
        self.$recipe.id = recipeID
        self.tag = tag
    }
}
