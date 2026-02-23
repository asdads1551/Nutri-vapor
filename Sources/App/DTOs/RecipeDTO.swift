import Vapor

// MARK: - Recipe List Item
struct RecipeListItem: Content {
    let id: UUID
    let name: String
    let calories: Int
    let cookingTimeMin: Int
    let servings: Int
    let priceNtd: Double
    let tags: [String]
    let cuisineType: String?
    let imageURL: String?
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, calories, servings, tags
        case cookingTimeMin = "cooking_time_min"
        case priceNtd = "price_ntd"
        case cuisineType = "cuisine_type"
        case imageURL = "image_url"
        case isFavorite = "is_favorite"
    }
}

// MARK: - Recipe Detail
struct RecipeDetailResponse: Content {
    let id: UUID
    let name: String
    let description: String?
    let calories: Int
    let cookingTimeMin: Int
    let difficulty: String
    let servings: Int
    let priceNtd: Double
    let nutrition: NutritionInfoResponse
    let ingredients: [IngredientResponse]
    let tags: [String]
    let cuisineType: String?
    let steps: [String]?
    let imageURL: String?
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, calories, difficulty, servings, nutrition, ingredients, tags, steps
        case cookingTimeMin = "cooking_time_min"
        case priceNtd = "price_ntd"
        case cuisineType = "cuisine_type"
        case imageURL = "image_url"
        case isFavorite = "is_favorite"
    }
}

// MARK: - Nutrition Info Response
struct NutritionInfoResponse: Content {
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double

    enum CodingKeys: String, CodingKey {
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
    }
}

// MARK: - Ingredient Response
struct IngredientResponse: Content {
    let name: String
    let amount: String
    let unit: String?
}

// MARK: - Recommended Recipe Response
struct RecommendedRecipeResponse: Content {
    let gaps: NutritionGaps
    let recipes: [RecommendedRecipeItem]
}

struct NutritionGaps: Content {
    let proteinG: Double
    let fiberG: Double
    let caloriesRemaining: Double

    enum CodingKeys: String, CodingKey {
        case proteinG = "protein_g"
        case fiberG = "fiber_g"
        case caloriesRemaining = "calories_remaining"
    }
}

struct RecommendedRecipeItem: Content {
    let recipe: RecipeListItem
    let matchReason: String

    enum CodingKeys: String, CodingKey {
        case recipe
        case matchReason = "match_reason"
    }
}
