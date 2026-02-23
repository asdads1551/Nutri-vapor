import Vapor

// MARK: - Meal Type
// Maps to iOS MealType: "早餐", "午餐", "晚餐", "點心"
enum MealTypeDB: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack

    /// Convert from iOS Chinese rawValue
    init?(chinese: String) {
        switch chinese {
        case "早餐": self = .breakfast
        case "午餐": self = .lunch
        case "晚餐": self = .dinner
        case "點心": self = .snack
        default: return nil
        }
    }

    /// Convert to iOS Chinese rawValue for API response
    var chinese: String {
        switch self {
        case .breakfast: return "早餐"
        case .lunch: return "午餐"
        case .dinner: return "晚餐"
        case .snack: return "點心"
        }
    }
}

// MARK: - Diet Type
// Maps to iOS DietType: "一般飲食", "素食", etc.
enum DietTypeDB: String, Codable, CaseIterable {
    case standard
    case vegetarian
    case vegan
    case pescatarian
    case keto
    case paleo
    case mediterranean
    case lowFodmap = "low_fodmap"
    case lowCarb = "low_carb"

    init?(chinese: String) {
        switch chinese {
        case "一般飲食": self = .standard
        case "素食": self = .vegetarian
        case "純素": self = .vegan
        case "海鮮素": self = .pescatarian
        case "生酮飲食": self = .keto
        case "原始人飲食": self = .paleo
        case "地中海飲食": self = .mediterranean
        case "低 FODMAP": self = .lowFodmap
        default: return nil
        }
    }

    var chinese: String {
        switch self {
        case .standard: return "一般飲食"
        case .vegetarian: return "素食"
        case .vegan: return "純素"
        case .pescatarian: return "海鮮素"
        case .keto: return "生酮飲食"
        case .paleo: return "原始人飲食"
        case .mediterranean: return "地中海飲食"
        case .lowFodmap: return "低 FODMAP"
        case .lowCarb: return "低碳水"
        }
    }
}

// MARK: - Cuisine Type
// Maps to iOS CuisineType: "台灣料理", "中華料理", etc.
enum CuisineTypeDB: String, Codable, CaseIterable {
    case taiwanese
    case chinese
    case japanese
    case korean
    case thai
    case vietnamese
    case western
    case italian
    case indian
    case mexican

    init?(chinese: String) {
        switch chinese {
        case "台灣料理": self = .taiwanese
        case "中華料理": self = .chinese
        case "日本料理": self = .japanese
        case "韓國料理": self = .korean
        case "泰式料理": self = .thai
        case "越南料理": self = .vietnamese
        case "西式料理": self = .western
        case "義式料理": self = .italian
        case "印度料理": self = .indian
        case "墨西哥料理": self = .mexican
        default: return nil
        }
    }

    var chinese: String {
        switch self {
        case .taiwanese: return "台灣料理"
        case .chinese: return "中華料理"
        case .japanese: return "日本料理"
        case .korean: return "韓國料理"
        case .thai: return "泰式料理"
        case .vietnamese: return "越南料理"
        case .western: return "西式料理"
        case .italian: return "義式料理"
        case .indian: return "印度料理"
        case .mexican: return "墨西哥料理"
        }
    }
}

// MARK: - Allergen
// Maps to iOS Allergen: "堅果", "乳製品", etc.
enum AllergenDB: String, Codable, CaseIterable {
    case nut
    case dairy
    case gluten
    case seafood
    case egg
    case soy

    init?(chinese: String) {
        switch chinese {
        case "堅果": self = .nut
        case "乳製品": self = .dairy
        case "麩質": self = .gluten
        case "海鮮": self = .seafood
        case "蛋": self = .egg
        case "大豆": self = .soy
        default: return nil
        }
    }

    var chinese: String {
        switch self {
        case .nut: return "堅果"
        case .dairy: return "乳製品"
        case .gluten: return "麩質"
        case .seafood: return "海鮮"
        case .egg: return "蛋"
        case .soy: return "大豆"
        }
    }
}

// MARK: - Recipe Tag
// Maps to iOS RecipeTag: "低卡", "高蛋白", etc.
enum RecipeTagDB: String, Codable, CaseIterable {
    case lowCalorie = "low_calorie"
    case highProtein = "high_protein"
    case vegetarian
    case omega3
    case glutenFree = "gluten_free"
    case dairy
    case keto
    case vegan

    init?(chinese: String) {
        switch chinese {
        case "低卡": self = .lowCalorie
        case "高蛋白": self = .highProtein
        case "素食": self = .vegetarian
        case "Omega-3": self = .omega3
        case "無麩質": self = .glutenFree
        case "含乳製品": self = .dairy
        case "生酮": self = .keto
        case "純素": self = .vegan
        default: return nil
        }
    }

    var chinese: String {
        switch self {
        case .lowCalorie: return "低卡"
        case .highProtein: return "高蛋白"
        case .vegetarian: return "素食"
        case .omega3: return "Omega-3"
        case .glutenFree: return "無麩質"
        case .dairy: return "含乳製品"
        case .keto: return "生酮"
        case .vegan: return "純素"
        }
    }
}

// MARK: - User Role
enum UserRole: String, Codable, CaseIterable {
    case user
    case admin
}

// MARK: - Gender
enum Gender: String, Codable, CaseIterable {
    case male
    case female
    case other
}

// MARK: - Activity Level
enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive = "very_active"
}

// MARK: - Food Source
enum FoodSource: String, Codable, CaseIterable {
    case manual
    case barcode
}

// MARK: - Recipe Difficulty
enum RecipeDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard
}

// MARK: - Push Type
enum PushType: String, Codable, CaseIterable {
    case mealRemind = "meal_remind"
    case water
    case nutritionAlert = "nutrition_alert"
    case weeklyReport = "weekly_report"
}

// MARK: - Push Status
enum PushStatus: String, Codable, CaseIterable {
    case sent
    case delivered
    case failed
    case clicked
}
