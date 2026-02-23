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
    /// Register a new user using Firebase ID Token
    @Sendable
    func register(req: Request) async throws -> AuthResponse {
        guard let firebaseUser = req.firebaseUser else {
            throw Abort(.unauthorized, reason: "Firebase authentication required")
        }

        let body = try? req.content.decode(RegisterRequest.self)

        // Check if user already exists
        if let existingUser = try await User.query(on: req.db)
            .filter(\.$firebaseUID == firebaseUser.uid)
            .first() {
            // User exists, return login response
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

        // Create new user
        let user = User(
            firebaseUID: firebaseUser.uid,
            email: firebaseUser.email,
            firstName: body?.firstName,
            lastName: body?.lastName
        )
        try await user.save(on: req.db)

        // Create default profile
        let profile = UserProfile(userID: user.id!, displayName: body?.firstName)
        try await profile.save(on: req.db)

        // Create default nutrition goals
        let goals = NutritionGoal(userID: user.id!)
        try await goals.save(on: req.db)

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

    // MARK: - POST /auth/logout
    @Sendable
    func logout(req: Request) async throws -> SuccessResponse {
        // Server-side session cleanup if needed
        SuccessResponse(message: "Logged out successfully")
    }

    // MARK: - DELETE /auth/account
    /// Delete user account (App Store compliance requirement)
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

        // Soft delete
        try await user.delete(on: req.db)
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
