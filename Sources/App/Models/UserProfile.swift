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
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        displayName: String? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.displayName = displayName
    }
}
