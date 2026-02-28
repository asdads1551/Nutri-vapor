import Fluent
import Vapor

final class UserProfile: Model, Content, @unchecked Sendable {
    static let schema = "user_profiles"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "display_name") var displayName: String?
    @Field(key: "avatar_url") var avatarURL: String?
    @Field(key: "gender") var gender: Gender?
    @Field(key: "birth_date") var birthDate: Date?
    @Field(key: "height_cm") var heightCm: Double?
    @Field(key: "weight_kg") var weightKg: Double?
    @Field(key: "activity_level") var activityLevel: ActivityLevel?
    @Field(key: "diet_type") var dietType: DietTypeDB?
    @Field(key: "calorie_goal") var calorieGoal: Int?
    @Field(key: "allergies") var allergies: [String]?

    // Dietary preferences (frontend-aligned)
    @Field(key: "cuisine_preferences") var cuisinePreferences: [String]?
    @Field(key: "prefer_high_protein") var preferHighProtein: Bool
    @Field(key: "prefer_low_carb") var preferLowCarb: Bool
    @Field(key: "prefer_low_sodium") var preferLowSodium: Bool
    @Field(key: "prefer_low_sugar") var preferLowSugar: Bool
    @Field(key: "avoid_spicy") var avoidSpicy: Bool

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete) var deletedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        displayName: String? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.displayName = displayName
        self.preferHighProtein = false
        self.preferLowCarb = false
        self.preferLowSodium = false
        self.preferLowSugar = false
        self.avoidSpicy = false
    }
}
