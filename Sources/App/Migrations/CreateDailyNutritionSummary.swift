import Fluent

struct CreateDailyNutritionSummary: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("daily_nutrition_summary")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("date", .date, .required)
            .field("total_calories", .double, .required, .custom("DEFAULT 0"))
            .field("total_protein", .double, .required, .custom("DEFAULT 0"))
            .field("total_carbs", .double, .required, .custom("DEFAULT 0"))
            .field("total_fat", .double, .required, .custom("DEFAULT 0"))
            .field("total_fiber", .double, .required, .custom("DEFAULT 0"))
            .field("total_sugar", .double, .required, .custom("DEFAULT 0"))
            .field("total_sodium", .double, .required, .custom("DEFAULT 0"))
            .field("total_water_ml", .int, .required, .custom("DEFAULT 0"))
            .field("entry_count", .int, .required, .custom("DEFAULT 0"))
            .field("goal_met", .bool, .required, .custom("DEFAULT false"))
            .field("score", .int, .required, .custom("DEFAULT 0"))
            .field("updated_at", .datetime)
            .unique(on: "user_id", "date")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("daily_nutrition_summary").delete()
    }
}
