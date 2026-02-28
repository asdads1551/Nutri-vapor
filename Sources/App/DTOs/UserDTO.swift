import Vapor

// MARK: - User Detail Response (matches frontend UserResponse)
struct UserDetailResponse: Content {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let avatarUrl: String?
    let dateCreated: Date?
    let lastLoginDate: Date?

    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"
        case dateCreated = "date_created"
        case lastLoginDate = "last_login_date"
    }
}

// MARK: - Update User Request (frontend-aligned)
struct UpdateUserRequest: Content, Validatable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case avatarUrl = "avatar_url"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("first_name", as: String?.self, is: .nil || .count(1...100), required: false)
        validations.add("last_name", as: String?.self, is: .nil || .count(1...100), required: false)
        validations.add("email", as: String?.self, is: .nil || .email, required: false)
        validations.add("avatar_url", as: String?.self, is: .nil || .count(1...2048), required: false)
    }
}

// MARK: - Profile Response (matches frontend UserProfileResponse)
// Combines data from user_profiles table + user_preferences table (3NF)
struct ProfileResponse: Content {
    let dietType: String?
    let allergens: [String]?
    let cuisinePreferences: [String]?
    let preferHighProtein: Bool
    let preferLowCarb: Bool
    let preferLowSodium: Bool
    let preferLowSugar: Bool
    let avoidSpicy: Bool
    let language: String?
    let theme: String?
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case dietType = "diet_type"
        case allergens
        case cuisinePreferences = "cuisine_preferences"
        case preferHighProtein = "prefer_high_protein"
        case preferLowCarb = "prefer_low_carb"
        case preferLowSodium = "prefer_low_sodium"
        case preferLowSugar = "prefer_low_sugar"
        case avoidSpicy = "avoid_spicy"
        case language, theme
        case onboardingCompleted = "onboarding_completed"
    }
}

// MARK: - Update Profile Request (frontend-aligned)
struct UpdateProfileRequest: Content, Validatable {
    let dietType: String?
    let allergens: [String]?
    let cuisinePreferences: [String]?
    let preferHighProtein: Bool?
    let preferLowCarb: Bool?
    let preferLowSodium: Bool?
    let preferLowSugar: Bool?
    let avoidSpicy: Bool?
    let language: String?
    let theme: String?
    let onboardingCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case dietType = "diet_type"
        case allergens
        case cuisinePreferences = "cuisine_preferences"
        case preferHighProtein = "prefer_high_protein"
        case preferLowCarb = "prefer_low_carb"
        case preferLowSodium = "prefer_low_sodium"
        case preferLowSugar = "prefer_low_sugar"
        case avoidSpicy = "avoid_spicy"
        case language, theme
        case onboardingCompleted = "onboarding_completed"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("diet_type", as: String?.self, is: .nil || .count(1...50), required: false)
        validations.add("allergens", as: [String]?.self, is: .nil || .count(...20), required: false)
        validations.add("cuisine_preferences", as: [String]?.self, is: .nil || .count(...20), required: false)
        validations.add("language", as: String?.self, is: .nil || .count(2...10), required: false)
        validations.add("theme", as: String?.self, is: .nil || .count(1...20), required: false)
    }
}

// MARK: - Goals Response (matches frontend NutritionGoalsResponse)
// DB column -> DTO field mapping done in controller
struct GoalsResponse: Content {
    let calorieGoal: Double?
    let proteinGoal: Double?
    let carbsGoal: Double?
    let fatGoal: Double?
    let fiberGoal: Double?
    let sugarGoal: Double?
    let sodiumGoal: Double?

    enum CodingKeys: String, CodingKey {
        case calorieGoal = "calorie_goal"
        case proteinGoal = "protein_goal"
        case carbsGoal = "carbs_goal"
        case fatGoal = "fat_goal"
        case fiberGoal = "fiber_goal"
        case sugarGoal = "sugar_goal"
        case sodiumGoal = "sodium_goal"
    }
}

// MARK: - Update Goals Request (frontend-aligned)
struct UpdateGoalsRequest: Content, Validatable {
    let calorieGoal: Double?
    let proteinGoal: Double?
    let carbsGoal: Double?
    let fatGoal: Double?
    let fiberGoal: Double?
    let sugarGoal: Double?
    let sodiumGoal: Double?

    enum CodingKeys: String, CodingKey {
        case calorieGoal = "calorie_goal"
        case proteinGoal = "protein_goal"
        case carbsGoal = "carbs_goal"
        case fatGoal = "fat_goal"
        case fiberGoal = "fiber_goal"
        case sugarGoal = "sugar_goal"
        case sodiumGoal = "sodium_goal"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("calorie_goal", as: Double?.self, is: .nil || .range(500...10000), required: false)
        validations.add("protein_goal", as: Double?.self, is: .nil || .range(0...500), required: false)
        validations.add("carbs_goal", as: Double?.self, is: .nil || .range(0...1000), required: false)
        validations.add("fat_goal", as: Double?.self, is: .nil || .range(0...500), required: false)
        validations.add("fiber_goal", as: Double?.self, is: .nil || .range(0...200), required: false)
        validations.add("sugar_goal", as: Double?.self, is: .nil || .range(0...500), required: false)
        validations.add("sodium_goal", as: Double?.self, is: .nil || .range(0...10000), required: false)
    }
}
