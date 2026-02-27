import Vapor

// MARK: - Create Food Entry Request
struct CreateFoodEntryRequest: Content, Validatable {
    let mealType: String
    let foodName: String
    let portionSize: Double?
    let portionUnit: String?
    let calories: Double
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let fiberG: Double?
    let sugarG: Double?
    let sodiumMg: Double?
    let potassiumMg: Double?
    let calciumMg: Double?
    let ironMg: Double?
    let zincMg: Double?
    let vitaminCMg: Double?
    let vitaminDMcg: Double?
    let eatenAt: Date?

    enum CodingKeys: String, CodingKey {
        case mealType = "meal_type"
        case foodName = "food_name"
        case portionSize = "portion_size"
        case portionUnit = "portion_unit"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case potassiumMg = "potassium_mg"
        case calciumMg = "calcium_mg"
        case ironMg = "iron_mg"
        case zincMg = "zinc_mg"
        case vitaminCMg = "vitamin_c_mg"
        case vitaminDMcg = "vitamin_d_mcg"
        case eatenAt = "eaten_at"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("food_name", as: String.self, is: .count(1...200))
        validations.add("calories", as: Double.self, is: .range(0...50000))
        validations.add("protein_g", as: Double?.self, required: false, is: .nil || .range(0...2000))
        validations.add("carbs_g", as: Double?.self, required: false, is: .nil || .range(0...2000))
        validations.add("fat_g", as: Double?.self, required: false, is: .nil || .range(0...2000))
        validations.add("fiber_g", as: Double?.self, required: false, is: .nil || .range(0...500))
        validations.add("sugar_g", as: Double?.self, required: false, is: .nil || .range(0...2000))
        validations.add("sodium_mg", as: Double?.self, required: false, is: .nil || .range(0...100000))
    }
}

// MARK: - Update Food Entry Request
struct UpdateFoodEntryRequest: Content, Validatable {
    let mealType: String?
    let foodName: String?
    let calories: Double?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let fiberG: Double?
    let sugarG: Double?
    let sodiumMg: Double?

    enum CodingKeys: String, CodingKey {
        case mealType = "meal_type"
        case foodName = "food_name"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("food_name", as: String?.self, required: false, is: .nil || .count(1...200))
        validations.add("calories", as: Double?.self, required: false, is: .nil || .range(0...50000))
        validations.add("protein_g", as: Double?.self, required: false, is: .nil || .range(0...2000))
        validations.add("carbs_g", as: Double?.self, required: false, is: .nil || .range(0...2000))
        validations.add("fat_g", as: Double?.self, required: false, is: .nil || .range(0...2000))
    }
}

// MARK: - Food Entry Response
struct FoodEntryResponse: Content {
    let id: UUID
    let mealType: String
    let foodName: String
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double
    let eatenAt: Date
    let dailySummary: DailySummaryBrief?

    enum CodingKeys: String, CodingKey {
        case id
        case mealType = "meal_type"
        case foodName = "food_name"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case eatenAt = "eaten_at"
        case dailySummary = "daily_summary"
    }
}

// MARK: - Daily Summary Brief (embedded in entry response)
struct DailySummaryBrief: Content {
    let totalCalories: Double
    let calorieGoal: Double
    let progressPct: Int

    enum CodingKeys: String, CodingKey {
        case totalCalories = "total_calories"
        case calorieGoal = "calorie_goal"
        case progressPct = "progress_pct"
    }
}

// MARK: - Daily Summary Response
struct DailySummaryResponse: Content {
    let date: String
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let totalFiber: Double
    let entryCount: Int
    let goalMet: Bool
    let score: Int

    enum CodingKeys: String, CodingKey {
        case date
        case totalCalories = "total_calories"
        case totalProtein = "total_protein"
        case totalCarbs = "total_carbs"
        case totalFat = "total_fat"
        case totalFiber = "total_fiber"
        case entryCount = "entry_count"
        case goalMet = "goal_met"
        case score
    }
}

// MARK: - Trend Data Point
struct TrendDataPoint: Content {
    let date: String
    let value: Double
}

// MARK: - Trend Response
struct TrendResponse: Content {
    let metric: String
    let range: String
    let data: [TrendDataPoint]
    let average: Double
    let goal: Double
    let daysGoalMet: Int

    enum CodingKeys: String, CodingKey {
        case metric, range, data, average, goal
        case daysGoalMet = "days_goal_met"
    }
}

// MARK: - Sync Request
struct NutritionSyncRequest: Content, Validatable {
    let entries: [CreateFoodEntryRequest]
    let lastSyncAt: Date?

    enum CodingKeys: String, CodingKey {
        case entries
        case lastSyncAt = "last_sync_at"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("entries", as: [CreateFoodEntryRequest].self, is: .count(...APIConstants.maxSyncBatchSize))
    }
}

// MARK: - Sync Response
struct NutritionSyncResponse: Content {
    let synced: [FoodEntryResponse]
    let serverUpdates: [FoodEntryResponse]

    enum CodingKeys: String, CodingKey {
        case synced
        case serverUpdates = "server_updates"
    }
}
