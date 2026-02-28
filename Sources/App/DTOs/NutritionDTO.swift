import Vapor

// MARK: - Create Food Entry Request (frontend-aligned)
// Frontend property -> wire format -> DB column mapping:
//   name -> name -> food_name
//   carbs -> carbs -> carbs_g
//   protein -> protein -> protein_g
//   vitaminC -> vitamin_c -> vitamin_c_mg
//   timestamp -> timestamp -> eaten_at
struct CreateFoodEntryRequest: Content, Validatable {
    let name: String
    let calories: Double
    let carbs: Double?
    let protein: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let potassium: Double?
    let calcium: Double?
    let iron: Double?
    let zinc: Double?
    let vitaminC: Double?
    let vitaminD: Double?
    let mealType: String
    let imageUrl: String?
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case name, calories, carbs, protein, fat, fiber, sugar, sodium
        case potassium, calcium, iron, zinc
        case vitaminC = "vitamin_c"
        case vitaminD = "vitamin_d"
        case mealType = "meal_type"
        case imageUrl = "image_url"
        case timestamp
    }

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(1...200))
        validations.add("calories", as: Double.self, is: .range(0...50000))
        validations.add("protein", as: Double?.self, is: .nil || .range(0...2000), required: false)
        validations.add("carbs", as: Double?.self, is: .nil || .range(0...2000), required: false)
        validations.add("fat", as: Double?.self, is: .nil || .range(0...2000), required: false)
        validations.add("fiber", as: Double?.self, is: .nil || .range(0...500), required: false)
        validations.add("sugar", as: Double?.self, is: .nil || .range(0...2000), required: false)
        validations.add("sodium", as: Double?.self, is: .nil || .range(0...100000), required: false)
        validations.add("potassium", as: Double?.self, is: .nil || .range(0...50000), required: false)
        validations.add("calcium", as: Double?.self, is: .nil || .range(0...50000), required: false)
        validations.add("iron", as: Double?.self, is: .nil || .range(0...5000), required: false)
        validations.add("zinc", as: Double?.self, is: .nil || .range(0...5000), required: false)
        validations.add("vitamin_c", as: Double?.self, is: .nil || .range(0...100000), required: false)
        validations.add("vitamin_d", as: Double?.self, is: .nil || .range(0...50000), required: false)
        validations.add("image_url", as: String?.self, is: .nil || .count(1...2048), required: false)
    }
}

// MARK: - Update Food Entry Request (frontend-aligned)
struct UpdateFoodEntryRequest: Content, Validatable {
    let name: String?
    let calories: Double?
    let carbs: Double?
    let protein: Double?
    let fat: Double?
    let mealType: String?

    enum CodingKeys: String, CodingKey {
        case name, calories, carbs, protein, fat
        case mealType = "meal_type"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String?.self, is: .nil || .count(1...200), required: false)
        validations.add("calories", as: Double?.self, is: .nil || .range(0...50000), required: false)
        validations.add("protein", as: Double?.self, is: .nil || .range(0...2000), required: false)
        validations.add("carbs", as: Double?.self, is: .nil || .range(0...2000), required: false)
        validations.add("fat", as: Double?.self, is: .nil || .range(0...2000), required: false)
    }
}

// MARK: - Food Entry Response (frontend-aligned)
struct FoodEntryResponse: Content {
    let id: String
    let name: String
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let potassium: Double
    let calcium: Double
    let iron: Double
    let zinc: Double
    let vitaminC: Double
    let vitaminD: Double
    let mealType: String
    let imageUrl: String?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, name, calories, carbs, protein, fat, fiber, sugar, sodium
        case potassium, calcium, iron, zinc
        case vitaminC = "vitamin_c"
        case vitaminD = "vitamin_d"
        case mealType = "meal_type"
        case imageUrl = "image_url"
        case timestamp
    }
}

// MARK: - Daily Summary Response (frontend-aligned: NutritionSummaryResponse)
struct DailySummaryResponse: Content {
    let date: String?
    let totalCalories: Double
    let totalCarbs: Double
    let totalProtein: Double
    let totalFat: Double
    let totalFiber: Double
    let totalSugar: Double
    let totalSodium: Double
    let totalPotassium: Double
    let totalCalcium: Double
    let totalIron: Double
    let totalZinc: Double
    let totalVitaminC: Double
    let totalVitaminD: Double
    let entryCount: Int

    enum CodingKeys: String, CodingKey {
        case date
        case totalCalories = "total_calories"
        case totalCarbs = "total_carbs"
        case totalProtein = "total_protein"
        case totalFat = "total_fat"
        case totalFiber = "total_fiber"
        case totalSugar = "total_sugar"
        case totalSodium = "total_sodium"
        case totalPotassium = "total_potassium"
        case totalCalcium = "total_calcium"
        case totalIron = "total_iron"
        case totalZinc = "total_zinc"
        case totalVitaminC = "total_vitamin_c"
        case totalVitaminD = "total_vitamin_d"
        case entryCount = "entry_count"
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

// MARK: - Sync Request (frontend-aligned: supports create/update/delete actions)
struct NutritionSyncRequest: Content, Validatable {
    let entries: [SyncEntry]
    let lastSyncedAt: Date?

    enum CodingKeys: String, CodingKey {
        case entries
        case lastSyncedAt = "last_synced_at"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("entries", as: [SyncEntry].self, is: .count(...APIConstants.maxSyncBatchSize))
    }
}

struct SyncEntry: Content {
    let id: String?
    let data: CreateFoodEntryRequest?
    let action: String   // "create", "update", "delete"
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, data, action
        case updatedAt = "updated_at"
    }
}

// MARK: - Sync Response (frontend-aligned)
struct NutritionSyncResponse: Content {
    let synced: Int
    let conflicts: [SyncConflict]?
}

struct SyncConflict: Content {
    let id: String
    let serverVersion: FoodEntryResponse

    enum CodingKeys: String, CodingKey {
        case id
        case serverVersion = "server_version"
    }
}
