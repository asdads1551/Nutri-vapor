import Fluent

struct CreatePushLogs: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("push_logs")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("type", .string, .required)
            .field("title", .string, .required)
            .field("body", .string, .required)
            .field("status", .string, .required, .custom("DEFAULT 'sent'"))
            .field("sent_at", .datetime, .required)
            .field("clicked_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("push_logs").delete()
    }
}
