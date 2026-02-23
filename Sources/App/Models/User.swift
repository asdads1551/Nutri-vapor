import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id) var id: UUID?
    @Field(key: "firebase_uid") var firebaseUID: String
    @Field(key: "email") var email: String?
    @Field(key: "first_name") var firstName: String?
    @Field(key: "last_name") var lastName: String?
    @Field(key: "role") var role: UserRole
    @Field(key: "is_premium") var isPremium: Bool
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete) var deletedAt: Date?

    // Relations
    @Children(for: \.$user) var foodEntries: [FoodEntry]
    @Children(for: \.$user) var favorites: [UserFavorite]

    init() {}

    init(
        id: UUID? = nil,
        firebaseUID: String,
        email: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        role: UserRole = .user,
        isPremium: Bool = false
    ) {
        self.id = id
        self.firebaseUID = firebaseUID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.isPremium = isPremium
    }
}
