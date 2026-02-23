import Fluent

struct CreateUserFavorites: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_favorites")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("recipe_id", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .unique(on: "user_id", "recipe_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_favorites").delete()
    }
}
