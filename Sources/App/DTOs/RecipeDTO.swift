import Vapor

// MARK: - Unified Recipe Response (matches frontend RecipeResponse)
// Merges former RecipeListItem + RecipeDetailResponse
struct RecipeResponse: Content {
    let id: String
    let name: String
    let description: String?
    let iconName: String
    let iconBackgroundColorHex: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let cookingTime: Int
    let difficulty: String?
    let servings: Int
    let price: Int
    let tags: [String]
    let allergens: [String]
    let ingredients: [IngredientResponse]
    let steps: [String]?
    let cuisineType: String?
    let imageUrl: String?
    let imageBase64: String?
    let audioUrl: String?
    let authorId: String?
    let authorName: String?
    let isFavorite: Bool?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, calories, protein, carbs, fat, fiber
        case difficulty, servings, tags, allergens, ingredients, steps, price
        case iconName = "icon_name"
        case iconBackgroundColorHex = "icon_background_color_hex"
        case cookingTime = "cooking_time"
        case cuisineType = "cuisine_type"
        case imageUrl = "image_url"
        case imageBase64 = "image_base64"
        case audioUrl = "audio_url"
        case authorId = "author_id"
        case authorName = "author_name"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
    }
}

// MARK: - Create Recipe Request (NEW endpoint)
struct CreateRecipeRequest: Content, Validatable {
    let name: String
    let description: String?
    let iconName: String?
    let iconBackgroundColorHex: String?
    let calories: Int
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let cookingTime: Int
    let difficulty: String?
    let servings: Int?
    let price: Int?
    let tags: [String]?
    let allergens: [String]?
    let ingredients: [CreateIngredientRequest]?
    let steps: [String]?
    let cuisineType: String?
    let imageUrl: String?
    let imageBase64: String?
    let audioUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, description, calories, protein, carbs, fat, fiber
        case difficulty, servings, tags, allergens, ingredients, steps, price
        case iconName = "icon_name"
        case iconBackgroundColorHex = "icon_background_color_hex"
        case cookingTime = "cooking_time"
        case cuisineType = "cuisine_type"
        case imageUrl = "image_url"
        case imageBase64 = "image_base64"
        case audioUrl = "audio_url"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(1...200))
        validations.add("calories", as: Int.self, is: .range(0...50000))
        validations.add("cooking_time", as: Int.self, is: .range(1...1440))
        validations.add("tags", as: [String]?.self, is: .nil || .count(...20), required: false)
        validations.add("allergens", as: [String]?.self, is: .nil || .count(...20), required: false)
        validations.add("steps", as: [String]?.self, is: .nil || .count(...100), required: false)
        validations.add("icon_name", as: String?.self, is: .nil || .count(1...100), required: false)
        validations.add("icon_background_color_hex", as: String?.self, is: .nil || .count(1...20), required: false)
        validations.add("description", as: String?.self, is: .nil || .count(...5000), required: false)
        validations.add("servings", as: Int?.self, is: .nil || .range(1...100), required: false)
        validations.add("price", as: Int?.self, is: .nil || .range(0...1000000), required: false)
        validations.add("image_url", as: String?.self, is: .nil || .count(1...2048), required: false)
        validations.add("audio_url", as: String?.self, is: .nil || .count(1...2048), required: false)
        validations.add("image_base64", as: String?.self, is: .nil || .count(...5000000), required: false)
    }
}

struct CreateIngredientRequest: Content {
    let name: String
    let amount: String
    let unit: String?
}

// MARK: - Ingredient Response
struct IngredientResponse: Content {
    let name: String
    let amount: String
}

// MARK: - Favorite Request (body-based, not path param)
struct FavoriteRequest: Content, Validatable {
    let recipeId: String

    enum CodingKeys: String, CodingKey {
        case recipeId = "recipe_id"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("recipe_id", as: String.self, is: .count(36...36))
    }
}

// MARK: - Favorites List Response (matches frontend FavoriteListResponse)
struct FavoritesListResponse: Content {
    let recipeIds: [String]

    enum CodingKeys: String, CodingKey {
        case recipeIds = "recipe_ids"
    }
}
