import Fluent

struct AddMicronutrientsToDailySummary: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("daily_nutrition_summary")
            .field("total_potassium", .double, .sql(.default(0)))
            .field("total_calcium", .double, .sql(.default(0)))
            .field("total_iron", .double, .sql(.default(0)))
            .field("total_zinc", .double, .sql(.default(0)))
            .field("total_vitamin_c", .double, .sql(.default(0)))
            .field("total_vitamin_d", .double, .sql(.default(0)))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("daily_nutrition_summary")
            .deleteField("total_potassium")
            .deleteField("total_calcium")
            .deleteField("total_iron")
            .deleteField("total_zinc")
            .deleteField("total_vitamin_c")
            .deleteField("total_vitamin_d")
            .update()
    }
}
