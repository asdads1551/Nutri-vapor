import Vapor

// MARK: - Register Request
struct RegisterRequest: Content {
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

// MARK: - Auth Response
struct AuthResponse: Content {
    let user: UserResponse
    let token: String

    struct UserResponse: Content {
        let id: UUID
        let email: String?
        let firstName: String?
        let lastName: String?
        let isPremium: Bool

        enum CodingKeys: String, CodingKey {
            case id, email
            case firstName = "first_name"
            case lastName = "last_name"
            case isPremium = "is_premium"
        }
    }
}

// MARK: - Firebase Token Payload (decoded from middleware)
struct FirebaseTokenPayload {
    let uid: String
    let email: String?
}
