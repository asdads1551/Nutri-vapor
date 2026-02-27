import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
        auth.delete("account", use: deleteAccount)
    }

    // MARK: - POST /auth/register
    /// Register a new user using Firebase ID Token
    @Sendable
    func register(req: Request) async throws -> AuthResponse {
        guard let firebaseUser = req.firebaseUser else {
            throw Abort(.unauthorized, reason: "Firebase authentication required")
        }

        try? RegisterRequest.validate(content: req)
        let body = try? req.content.decode(RegisterRequest.self)

        // Check if user already exists
        if let existingUser = try await User.query(on: req.db)
            .filter(\.$firebaseUID == firebaseUser.uid)
            .first() {
            let token = try await generateJWT(for: existingUser, req: req)
            return AuthResponse(
                user: .init(
                    id: existingUser.id!,
                    email: existingUser.email,
                    firstName: existingUser.firstName,
                    lastName: existingUser.lastName,
                    isPremium: existingUser.isPremium
                ),
                token: token
            )
        }

        // Create new user with all related records in a transaction (#3)
        let user = User(
            firebaseUID: firebaseUser.uid,
            email: firebaseUser.email,
            firstName: body?.firstName,
            lastName: body?.lastName
        )

        try await req.db.transaction { db in
            try await user.save(on: db)

            let profile = UserProfile(userID: user.id!, displayName: body?.firstName)
            try await profile.save(on: db)

            let goals = NutritionGoal(userID: user.id!)
            try await goals.save(on: db)
        }

        req.logger.info("New user registered: \(user.id!)")

        let token = try await generateJWT(for: user, req: req)
        return AuthResponse(
            user: .init(
                id: user.id!,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                isPremium: user.isPremium
            ),
            token: token
        )
    }

    // MARK: - POST /auth/login
    @Sendable
    func login(req: Request) async throws -> AuthResponse {
        guard let firebaseUser = req.firebaseUser else {
            throw Abort(.unauthorized, reason: "Firebase authentication required")
        }

        guard let user = try await User.query(on: req.db)
            .filter(\.$firebaseUID == firebaseUser.uid)
            .first() else {
            throw Abort(.notFound, reason: "User not registered. Please register first.")
        }

        let token = try await generateJWT(for: user, req: req)
        return AuthResponse(
            user: .init(
                id: user.id!,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                isPremium: user.isPremium
            ),
            token: token
        )
    }

    // MARK: - DELETE /auth/account
    /// Delete user account and ALL related data (App Store / GDPR compliance) (#4)
    @Sendable
    func deleteAccount(req: Request) async throws -> SuccessResponse {
        guard let firebaseUser = req.firebaseUser else {
            throw Abort(.unauthorized)
        }

        guard let user = try await User.query(on: req.db)
            .filter(\.$firebaseUID == firebaseUser.uid)
            .first() else {
            throw Abort(.notFound, reason: "User not found")
        }

        let userID = user.id!

        // Delete all related data in a transaction, then hard-delete the user
        try await req.db.transaction { db in
            try await FoodEntry.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await DailyNutritionSummary.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await HealthSyncLog.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await UserFavorite.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await PushLog.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await NutritionGoal.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await NotificationSetting.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await UserProfile.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await user.delete(force: true, on: db)
        }

        req.logger.info("Account deleted for user: \(userID)")
        return SuccessResponse(message: "Account deleted successfully")
    }

    // MARK: - Helper
    private func generateJWT(for user: User, req: Request) async throws -> String {
        let payload = ServerJWTPayload(
            sub: .init(value: user.id!.uuidString),
            exp: .init(value: Date().addingTimeInterval(TimeInterval(APIConstants.jwtExpirationMinutes * 60))),
            iat: .init(value: Date())
        )
        return try await req.jwt.sign(payload)
    }
}
