import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
        auth.post("logout", use: logout)
        auth.delete("account", use: deleteAccount)
    }

    // MARK: - POST /auth/register
    /// Register a new user using Firebase ID Token from request body
    @Sendable
    func register(req: Request) async throws -> AuthResponse {
        try RegisterRequest.validate(content: req)
        let body = try req.content.decode(RegisterRequest.self)

        // Verify Firebase token from body
        let firebaseUser = try await FirebaseAuthMiddleware.verifyToken(
            body.firebaseToken,
            client: req.client,
            logger: req.logger
        )

        // Check if user already exists
        if let existingUser = try await User.query(on: req.db)
            .filter(\.$firebaseUID == firebaseUser.uid)
            .first() {
            // Update last login
            existingUser.lastLoginDate = Date()
            try await existingUser.save(on: req.db)

            let profile = try await UserProfile.query(on: req.db)
                .filter(\.$user.$id == existingUser.id!)
                .first()

            let token = try await generateJWT(for: existingUser, req: req)
            return AuthResponse(
                user: AuthUserResponse(
                    id: existingUser.id!.uuidString,
                    email: existingUser.email,
                    firstName: existingUser.firstName,
                    lastName: existingUser.lastName,
                    avatarUrl: profile?.avatarURL,
                    dateCreated: existingUser.createdAt,
                    lastLoginDate: existingUser.lastLoginDate
                ),
                token: token
            )
        }

        // Create new user with all related records in a transaction
        let user = User(
            firebaseUID: firebaseUser.uid,
            email: body.email ?? firebaseUser.email,
            firstName: body.firstName,
            lastName: body.lastName
        )
        user.lastLoginDate = Date()

        try await req.db.transaction { db in
            try await user.save(on: db)

            let profile = UserProfile(userID: user.id!, displayName: body.firstName)
            try await profile.save(on: db)

            let goals = NutritionGoal(userID: user.id!)
            try await goals.save(on: db)

            let preference = UserPreference(userID: user.id!)
            try await preference.save(on: db)
        }

        req.logger.info("New user registered: \(user.id!)")

        let token = try await generateJWT(for: user, req: req)
        return AuthResponse(
            user: AuthUserResponse(
                id: user.id!.uuidString,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                avatarUrl: nil,
                dateCreated: user.createdAt,
                lastLoginDate: user.lastLoginDate
            ),
            token: token
        )
    }

    // MARK: - POST /auth/login
    @Sendable
    func login(req: Request) async throws -> AuthResponse {
        try LoginRequest.validate(content: req)
        let body = try req.content.decode(LoginRequest.self)

        // Verify Firebase token from body
        let firebaseUser = try await FirebaseAuthMiddleware.verifyToken(
            body.firebaseToken,
            client: req.client,
            logger: req.logger
        )

        guard let user = try await User.query(on: req.db)
            .filter(\.$firebaseUID == firebaseUser.uid)
            .first() else {
            throw Abort(.notFound, reason: "User not registered. Please register first.")
        }

        // Update last login date
        user.lastLoginDate = Date()
        try await user.save(on: req.db)

        let profile = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .first()

        let token = try await generateJWT(for: user, req: req)
        return AuthResponse(
            user: AuthUserResponse(
                id: user.id!.uuidString,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                avatarUrl: profile?.avatarURL,
                dateCreated: user.createdAt,
                lastLoginDate: user.lastLoginDate
            ),
            token: token
        )
    }

    // MARK: - POST /auth/logout
    @Sendable
    func logout(req: Request) async throws -> SuccessResponse {
        SuccessResponse(message: "Logged out successfully")
    }

    // MARK: - DELETE /auth/account
    /// Delete user account and ALL related data (App Store / GDPR compliance)
    @Sendable
    func deleteAccount(req: Request) async throws -> SuccessResponse {
        // Verify Firebase token from Authorization header
        guard let bearerToken = req.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing Firebase ID token")
        }
        let firebaseUser = try await FirebaseAuthMiddleware.verifyToken(
            bearerToken,
            client: req.client,
            logger: req.logger
        )

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
            try await UserPreference.query(on: db).filter(\.$user.$id == userID).delete(force: true)
            try await UserProfile.query(on: db).filter(\.$user.$id == userID).delete(force: true)

            // Delete recipe allergens for user-authored recipes
            let userRecipes = try await Recipe.query(on: db)
                .filter(\.$author.$id == userID)
                .all()
            for recipe in userRecipes {
                try await RecipeAllergen.query(on: db)
                    .filter(\.$recipe.$id == recipe.id!)
                    .delete(force: true)
            }

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
