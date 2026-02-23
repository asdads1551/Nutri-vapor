import Fluent

struct CreateRecipeTags: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("recipe_tags")
            .id()
            .field("recipe_id", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
            .field("tag", .string, .required)
            .unique(on: "recipe_id", "tag")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("recipe_tags").delete()
    }
}
