import Fluent
import Vapor

final class UserPreference: Model, Content, @unchecked Sendable {
    static let schema = "user_preferences"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "language") var language: String?
    @Field(key: "theme") var theme: String?
    @Field(key: "onboarding_completed") var onboardingCompleted: Bool
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        language: String? = "zh-TW",
        theme: String? = "system",
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.$user.id = userID
        self.language = language
        self.theme = theme
        self.onboardingCompleted = onboardingCompleted
    }
}
