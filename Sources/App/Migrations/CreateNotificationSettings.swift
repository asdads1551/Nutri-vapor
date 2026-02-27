import Fluent

struct CreateNotificationSettings: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("notification_settings")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("meal_remind", .bool, .required, .sql(.default(true)))
            .field("water_remind", .bool, .required, .sql(.default(true)))
            .field("nutrition_alert", .bool, .required, .sql(.default(true)))
            .field("weekly_report", .bool, .required, .sql(.default(true)))
            .field("quiet_hours_start", .string)
            .field("quiet_hours_end", .string)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("notification_settings").delete()
    }
}
