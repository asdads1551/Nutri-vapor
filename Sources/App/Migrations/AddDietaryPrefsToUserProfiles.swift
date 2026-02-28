import Fluent

struct AddDietaryPrefsToUserProfiles: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_profiles")
            .field("cuisine_preferences", .array(of: .string))
            .field("prefer_high_protein", .bool, .sql(.default(false)))
            .field("prefer_low_carb", .bool, .sql(.default(false)))
            .field("prefer_low_sodium", .bool, .sql(.default(false)))
            .field("prefer_low_sugar", .bool, .sql(.default(false)))
            .field("avoid_spicy", .bool, .sql(.default(false)))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_profiles")
            .deleteField("cuisine_preferences")
            .deleteField("prefer_high_protein")
            .deleteField("prefer_low_carb")
            .deleteField("prefer_low_sodium")
            .deleteField("prefer_low_sugar")
            .deleteField("avoid_spicy")
            .update()
    }
}
