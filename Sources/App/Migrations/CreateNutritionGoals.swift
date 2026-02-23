import Fluent

struct CreateNutritionGoals: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("nutrition_goals")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("calories", .int, .required, .custom("DEFAULT 2000"))
            .field("protein_g", .double, .required, .custom("DEFAULT 60"))
            .field("carbs_g", .double, .required, .custom("DEFAULT 250"))
            .field("fat_g", .double, .required, .custom("DEFAULT 65"))
            .field("fiber_g", .double, .required, .custom("DEFAULT 25"))
            .field("sugar_g", .double, .required, .custom("DEFAULT 50"))
            .field("sodium_mg", .double, .required, .custom("DEFAULT 2300"))
            .field("water_ml", .int, .required, .custom("DEFAULT 2000"))
            .field("effective_date", .date, .required)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("nutrition_goals").delete()
    }
}
