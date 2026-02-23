import Fluent

struct CreateFoodEntries: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("food_entries")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("meal_type", .string, .required)
            .field("food_name", .string, .required)
            .field("portion_size", .double)
            .field("portion_unit", .string)
            .field("image_url", .string)
            .field("source", .string, .required, .custom("DEFAULT 'manual'"))
            // Macronutrients
            .field("calories", .double, .required)
            .field("protein_g", .double, .required, .custom("DEFAULT 0"))
            .field("carbs_g", .double, .required, .custom("DEFAULT 0"))
            .field("fat_g", .double, .required, .custom("DEFAULT 0"))
            .field("fiber_g", .double, .required, .custom("DEFAULT 0"))
            .field("sugar_g", .double, .required, .custom("DEFAULT 0"))
            // Micronutrients
            .field("sodium_mg", .double, .required, .custom("DEFAULT 0"))
            .field("potassium_mg", .double, .required, .custom("DEFAULT 0"))
            .field("calcium_mg", .double, .required, .custom("DEFAULT 0"))
            .field("iron_mg", .double, .required, .custom("DEFAULT 0"))
            .field("zinc_mg", .double, .required, .custom("DEFAULT 0"))
            .field("vitamin_c_mg", .double, .required, .custom("DEFAULT 0"))
            .field("vitamin_d_mcg", .double, .required, .custom("DEFAULT 0"))
            // Timestamps
            .field("eaten_at", .datetime, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()

        // Indexes for common queries
        try await database.schema("food_entries")
            .constraint(.custom("CREATE INDEX IF NOT EXISTS idx_food_entries_user_eaten ON food_entries(user_id, eaten_at)"))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("food_entries").delete()
    }
}
