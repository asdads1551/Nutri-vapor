import Fluent
import Vapor

/// Corresponds to iOS `Recipe` in Recipe.swift
final class Recipe: Model, Content, @unchecked Sendable {
    static let schema = "recipes"

    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "description") var description: String?
    @Field(key: "image_url") var imageURL: String?
    @Field(key: "calories") var calories: Int
    @Field(key: "cooking_time_min") var cookingTimeMin: Int
    @Field(key: "difficulty") var difficulty: RecipeDifficulty
    @Field(key: "servings") var servings: Int
    @Field(key: "price_ntd") var priceNtd: Double
    @Field(key: "protein_g") var proteinG: Double
    @Field(key: "carbs_g") var carbsG: Double
    @Field(key: "fat_g") var fatG: Double
    @Field(key: "fiber_g") var fiberG: Double
    @Field(key: "cuisine_type") var cuisineType: CuisineTypeDB?
    @Field(key: "steps") var steps: [String]?
    @Field(key: "is_published") var isPublished: Bool

    // Frontend-aligned fields
    @Field(key: "icon_name") var iconName: String?
    @Field(key: "icon_background_color_hex") var iconBackgroundColorHex: String?
    @OptionalParent(key: "author_id") var author: User?
    @Field(key: "image_base64") var imageBase64: String?
    @Field(key: "audio_url") var audioURL: String?

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    // Relations
    @Children(for: \.$recipe) var tags: [RecipeTagModel]
    @Children(for: \.$recipe) var ingredients: [RecipeIngredient]
    @Children(for: \.$recipe) var favorites: [UserFavorite]
    @Children(for: \.$recipe) var allergens: [RecipeAllergen]

    init() {}

    init(
        id: UUID? = nil,
        name: String,
        calories: Int,
        cookingTimeMin: Int,
        difficulty: RecipeDifficulty = .easy,
        servings: Int = 2,
        priceNtd: Double = 0,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0,
        fiberG: Double = 0,
        cuisineType: CuisineTypeDB? = nil,
        isPublished: Bool = true
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.cookingTimeMin = cookingTimeMin
        self.difficulty = difficulty
        self.servings = servings
        self.priceNtd = priceNtd
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.cuisineType = cuisineType
        self.isPublished = isPublished
    }
}
