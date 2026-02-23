import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("firebase_uid", .string, .required)
            .field("email", .string)
            .field("first_name", .string)
            .field("last_name", .string)
            .field("role", .string, .required, .custom("DEFAULT 'user'"))
            .field("is_premium", .bool, .required, .custom("DEFAULT false"))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .unique(on: "firebase_uid")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
