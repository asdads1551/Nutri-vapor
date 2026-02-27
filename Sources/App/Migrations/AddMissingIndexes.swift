import Fluent

/// Adds missing database indexes for production query performance.
struct AddMissingIndexes: AsyncMigration {
    func prepare(on database: Database) async throws {
        // food_entries: compound index for meal-type filtering (per CLAUDE.md spec)
        try await database.execute(query: .init(string: """
            CREATE INDEX IF NOT EXISTS idx_food_entries_user_meal_eaten
            ON food_entries(user_id, meal_type, eaten_at)
            """))

        // recipes: filter published recipes efficiently
        try await database.execute(query: .init(string: """
            CREATE INDEX IF NOT EXISTS idx_recipes_published
            ON recipes(is_published) WHERE is_published = true
            """))

        // push_logs: query history by user and date range
        try await database.execute(query: .init(string: """
            CREATE INDEX IF NOT EXISTS idx_push_logs_user_sent
            ON push_logs(user_id, sent_at)
            """))

        // push_logs: filter by delivery status
        try await database.execute(query: .init(string: """
            CREATE INDEX IF NOT EXISTS idx_push_logs_status
            ON push_logs(status)
            """))

        // daily_nutrition_summary: date range queries for dashboard
        try await database.execute(query: .init(string: """
            CREATE INDEX IF NOT EXISTS idx_daily_summary_user_date
            ON daily_nutrition_summary(user_id, date)
            """))

        // nutrition_goals: FK lookup optimization
        try await database.execute(query: .init(string: """
            CREATE INDEX IF NOT EXISTS idx_nutrition_goals_user
            ON nutrition_goals(user_id)
            """))
    }

    func revert(on database: Database) async throws {
        try await database.execute(query: .init(string: "DROP INDEX IF EXISTS idx_food_entries_user_meal_eaten"))
        try await database.execute(query: .init(string: "DROP INDEX IF EXISTS idx_recipes_published"))
        try await database.execute(query: .init(string: "DROP INDEX IF EXISTS idx_push_logs_user_sent"))
        try await database.execute(query: .init(string: "DROP INDEX IF EXISTS idx_push_logs_status"))
        try await database.execute(query: .init(string: "DROP INDEX IF EXISTS idx_daily_summary_user_date"))
        try await database.execute(query: .init(string: "DROP INDEX IF EXISTS idx_nutrition_goals_user"))
    }
}
