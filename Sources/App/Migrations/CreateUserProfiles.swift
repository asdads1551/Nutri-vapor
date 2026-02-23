import Fluent

struct CreateUserProfiles: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_profiles")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("display_name", .string)
            .field("avatar_url", .string)
            .field("gender", .string)
            .field("birth_date", .date)
            .field("height_cm", .double)
            .field("weight_kg", .double)
            .field("activity_level", .string)
            .field("diet_type", .string)
            .field("calorie_goal", .int)
            .field("allergies", .array(of: .string))
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_profiles").delete()
    }
}
