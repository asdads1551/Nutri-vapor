import Fluent

struct CreateRecipeAllergens: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("recipe_allergens")
            .id()
            .field("recipe_id", .uuid, .required, .references("recipes", "id", onDelete: .cascade))
            .field("allergen", .string, .required)
            .unique(on: "recipe_id", "allergen")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("recipe_allergens").delete()
    }
}
