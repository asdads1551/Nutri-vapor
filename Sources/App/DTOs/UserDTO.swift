import Vapor

// MARK: - User Response
struct UserDetailResponse: Content {
    let id: UUID
    let email: String?
    let firstName: String?
    let lastName: String?
    let isPremium: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case isPremium = "is_premium"
        case createdAt = "created_at"
    }
}

// MARK: - Update User Request
struct UpdateUserRequest: Content {
    let firstName: String?
    let lastName: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
}

// MARK: - Profile Response
struct ProfileResponse: Content {
    let displayName: String?
    let avatarURL: String?
    let gender: String?
    let birthDate: Date?
    let heightCm: Double?
    let weightKg: Double?
    let activityLevel: String?
    let dietType: String?
    let calorieGoal: Int?
    let allergies: [String]?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case gender
        case birthDate = "birth_date"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case activityLevel = "activity_level"
        case dietType = "diet_type"
        case calorieGoal = "calorie_goal"
        case allergies
    }
}

// MARK: - Update Profile Request
struct UpdateProfileRequest: Content {
    let displayName: String?
    let gender: String?
    let birthDate: Date?
    let heightCm: Double?
    let weightKg: Double?
    let activityLevel: String?
    let dietType: String?
    let calorieGoal: Int?
    let allergies: [String]?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case gender
        case birthDate = "birth_date"
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case activityLevel = "activity_level"
        case dietType = "diet_type"
        case calorieGoal = "calorie_goal"
        case allergies
    }
}

// MARK: - Goals Response
struct GoalsResponse: Content {
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double
    let sugarG: Double
    let sodiumMg: Double
    let waterMl: Int

    enum CodingKeys: String, CodingKey {
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case waterMl = "water_ml"
    }
}

// MARK: - Update Goals Request
struct UpdateGoalsRequest: Content {
    let calories: Int?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let fiberG: Double?
    let sugarG: Double?
    let sodiumMg: Double?
    let waterMl: Int?

    enum CodingKeys: String, CodingKey {
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case waterMl = "water_ml"
    }
}
