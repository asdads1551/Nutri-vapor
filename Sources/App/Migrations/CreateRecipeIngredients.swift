import Fluent

struct CreateRecipeIngredients: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("recipe_ingredients")
            .id()
            .field("recipe_id", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("amount", .string, .required)
            .field("unit", .string)
            .field("sort_order", .int, .required, .custom("DEFAULT 0"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("recipe_ingredients").delete()
    }
}
