import Fluent
import Vapor

final class UserFavorite: Model, Content, @unchecked Sendable {
    static let schema = "user_favorites"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Parent(key: "recipe_id") var recipe: Recipe
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "deleted_at", on: .delete) var deletedAt: Date?

    init() {}

    init(id: UUID? = nil, userID: UUID, recipeID: UUID) {
        self.id = id
        self.$user.id = userID
        self.$recipe.id = recipeID
    }
}
