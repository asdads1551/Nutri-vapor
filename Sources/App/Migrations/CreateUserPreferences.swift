import Fluent

struct CreateUserPreferences: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_preferences")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("language", .string, .sql(.default("zh-TW")))
            .field("theme", .string, .sql(.default("system")))
            .field("onboarding_completed", .bool, .sql(.default(false)))
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_preferences").delete()
    }
}
