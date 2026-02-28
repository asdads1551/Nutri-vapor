import Fluent

struct AddSoftDeleteToAllModels: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Add deleted_at to each table that doesn't have it yet
        // (users table already has deleted_at from CreateUsers migration)
        let tables = [
            "food_entries", "user_profiles", "user_preferences",
            "daily_nutrition_summary", "nutrition_goals", "recipes",
            "recipe_ingredients", "recipe_tags", "recipe_allergens",
            "user_favorites", "health_sync_logs", "push_logs",
            "notification_settings"
        ]
        for table in tables {
            try await database.schema(table)
                .field("deleted_at", .datetime)
                .update()
        }
    }

    func revert(on database: any Database) async throws {
        let tables = [
            "food_entries", "user_profiles", "user_preferences",
            "daily_nutrition_summary", "nutrition_goals", "recipes",
            "recipe_ingredients", "recipe_tags", "recipe_allergens",
            "user_favorites", "health_sync_logs", "push_logs",
            "notification_settings"
        ]
        for table in tables {
            try await database.schema(table)
                .deleteField("deleted_at")
                .update()
        }
    }
}
