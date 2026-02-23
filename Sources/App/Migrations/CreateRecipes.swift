import Fluent

struct CreateRecipes: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("recipes")
            .id()
            .field("name", .string, .required)
            .field("description", .string)
            .field("image_url", .string)
            .field("calories", .int, .required)
            .field("cooking_time_min", .int, .required)
            .field("difficulty", .string, .required, .custom("DEFAULT 'easy'"))
            .field("servings", .int, .required, .custom("DEFAULT 2"))
            .field("price_ntd", .double, .required, .custom("DEFAULT 0"))
            .field("protein_g", .double, .required, .custom("DEFAULT 0"))
            .field("carbs_g", .double, .required, .custom("DEFAULT 0"))
            .field("fat_g", .double, .required, .custom("DEFAULT 0"))
            .field("fiber_g", .double, .required, .custom("DEFAULT 0"))
            .field("cuisine_type", .string)
            .field("steps", .array(of: .string))
            .field("is_published", .bool, .required, .custom("DEFAULT true"))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("recipes").delete()
    }
}
