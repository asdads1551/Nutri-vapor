import Vapor

// MARK: - Register Request (frontend-aligned)
// Frontend sends: firebase_token, first_name, last_name, email, apple_user_identifier
struct RegisterRequest: Content, Validatable {
    let firebaseToken: String
    let firstName: String?
    let lastName: String?
    let email: String?
    let appleUserIdentifier: String?

    enum CodingKeys: String, CodingKey {
        case firebaseToken = "firebase_token"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case appleUserIdentifier = "apple_user_identifier"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("firebase_token", as: String.self, is: .count(10...10000))
        validations.add("first_name", as: String?.self, is: .nil || .count(1...100), required: false)
        validations.add("last_name", as: String?.self, is: .nil || .count(1...100), required: false)
        validations.add("email", as: String?.self, is: .nil || .email, required: false)
        validations.add("apple_user_identifier", as: String?.self, is: .nil || .count(1...500), required: false)
    }
}

// MARK: - Login Request (frontend-aligned)
// Frontend sends: firebase_token
struct LoginRequest: Content, Validatable {
    let firebaseToken: String

    enum CodingKeys: String, CodingKey {
        case firebaseToken = "firebase_token"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("firebase_token", as: String.self, is: .count(10...10000))
    }
}

// MARK: - Auth Response
struct AuthResponse: Content {
    let user: AuthUserResponse
    let token: String
}

// MARK: - Auth User Response (matches frontend UserResponse)
struct AuthUserResponse: Content {
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

// MARK: - Firebase Token Payload (internal, decoded from verification)
struct FirebaseTokenPayload {
    let uid: String
    let email: String?
}
