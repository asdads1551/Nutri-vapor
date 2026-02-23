import Fluent

struct CreateHealthSyncLogs: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("health_sync_logs")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("date", .date, .required)
            .field("steps", .int)
            .field("active_cal", .double)
            .field("weight_kg", .double)
            .field("heart_rate", .int)
            .field("sleep_hours", .double)
            .field("synced_at", .datetime)
            .unique(on: "user_id", "date")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("health_sync_logs").delete()
    }
}
