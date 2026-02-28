import Fluent

struct AddRecipeAuthorAndIconFields: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("recipes")
            .field("icon_name", .string)
            .field("icon_background_color_hex", .string)
            .field("author_id", .uuid, .references("users", "id", onDelete: .setNull))
            .field("image_base64", .custom("TEXT"))
            .field("audio_url", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("recipes")
            .deleteField("icon_name")
            .deleteField("icon_background_color_hex")
            .deleteField("author_id")
            .deleteField("image_base64")
            .deleteField("audio_url")
            .update()
    }
}
