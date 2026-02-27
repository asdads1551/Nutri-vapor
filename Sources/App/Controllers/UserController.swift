import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get("me", use: getMe)
        users.patch("me", use: updateMe)
        users.get("me", "profile", use: getProfile)
        users.put("me", "profile", use: updateProfile)
        users.get("me", "goals", use: getGoals)
        users.put("me", "goals", use: updateGoals)
    }

    // MARK: - GET /users/me
    @Sendable
    func getMe(req: Request) async throws -> UserDetailResponse {
        let userID = try req.authenticatedUserID
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        return UserDetailResponse(
            id: user.id!,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            isPremium: user.isPremium,
            createdAt: user.createdAt
        )
    }

    // MARK: - PATCH /users/me
    @Sendable
    func updateMe(req: Request) async throws -> UserDetailResponse {
        let userID = try req.authenticatedUserID
        try UpdateUserRequest.validate(content: req)
        let body = try req.content.decode(UpdateUserRequest.self)

        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        if let firstName = body.firstName { user.firstName = firstName }
        if let lastName = body.lastName { user.lastName = lastName }
        if let email = body.email { user.email = email }

        try await user.save(on: req.db)

        return UserDetailResponse(
            id: user.id!,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            isPremium: user.isPremium,
            createdAt: user.createdAt
        )
    }

    // MARK: - GET /users/me/profile
    @Sendable
    func getProfile(req: Request) async throws -> ProfileResponse {
        let userID = try req.authenticatedUserID
        let profile = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()

        return ProfileResponse(
            displayName: profile?.displayName,
            avatarURL: profile?.avatarURL,
            gender: profile?.gender?.rawValue,
            birthDate: profile?.birthDate,
            heightCm: profile?.heightCm,
            weightKg: profile?.weightKg,
            activityLevel: profile?.activityLevel?.rawValue,
            dietType: profile?.dietType?.chinese,
            calorieGoal: profile?.calorieGoal,
            allergies: profile?.allergies
        )
    }

    // MARK: - PUT /users/me/profile
    @Sendable
    func updateProfile(req: Request) async throws -> ProfileResponse {
        let userID = try req.authenticatedUserID
        try UpdateProfileRequest.validate(content: req)
        let body = try req.content.decode(UpdateProfileRequest.self)

        let profile: UserProfile
        if let existing = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() {
            profile = existing
        } else {
            profile = UserProfile(userID: userID)
        }

        if let displayName = body.displayName { profile.displayName = displayName }
        if let gender = body.gender { profile.gender = Gender(rawValue: gender) }
        if let birthDate = body.birthDate { profile.birthDate = birthDate }
        if let heightCm = body.heightCm { profile.heightCm = heightCm }
        if let weightKg = body.weightKg { profile.weightKg = weightKg }
        if let activityLevel = body.activityLevel { profile.activityLevel = ActivityLevel(rawValue: activityLevel) }
        if let dietType = body.dietType { profile.dietType = DietTypeDB(rawValue: dietType) ?? DietTypeDB(chinese: dietType) }
        if let calorieGoal = body.calorieGoal { profile.calorieGoal = calorieGoal }
        if let allergies = body.allergies { profile.allergies = allergies }

        try await profile.save(on: req.db)

        return ProfileResponse(
            displayName: profile.displayName,
            avatarURL: profile.avatarURL,
            gender: profile.gender?.rawValue,
            birthDate: profile.birthDate,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            activityLevel: profile.activityLevel?.rawValue,
            dietType: profile.dietType?.chinese,
            calorieGoal: profile.calorieGoal,
            allergies: profile.allergies
        )
    }

    // MARK: - GET /users/me/goals
    @Sendable
    func getGoals(req: Request) async throws -> GoalsResponse {
        let userID = try req.authenticatedUserID
        let goals = try await NutritionGoal.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$effectiveDate, .descending)
            .first()

        return GoalsResponse(
            calories: goals?.calories ?? 2000,
            proteinG: goals?.proteinG ?? 60,
            carbsG: goals?.carbsG ?? 250,
            fatG: goals?.fatG ?? 65,
            fiberG: goals?.fiberG ?? 25,
            sugarG: goals?.sugarG ?? 50,
            sodiumMg: goals?.sodiumMg ?? 2300,
            waterMl: goals?.waterMl ?? 2000
        )
    }

    // MARK: - PUT /users/me/goals
    @Sendable
    func updateGoals(req: Request) async throws -> GoalsResponse {
        let userID = try req.authenticatedUserID
        try UpdateGoalsRequest.validate(content: req)
        let body = try req.content.decode(UpdateGoalsRequest.self)

        let goals: NutritionGoal
        if let existing = try await NutritionGoal.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$effectiveDate, .descending)
            .first() {
            goals = existing
        } else {
            goals = NutritionGoal(userID: userID)
        }

        if let calories = body.calories { goals.calories = calories }
        if let proteinG = body.proteinG { goals.proteinG = proteinG }
        if let carbsG = body.carbsG { goals.carbsG = carbsG }
        if let fatG = body.fatG { goals.fatG = fatG }
        if let fiberG = body.fiberG { goals.fiberG = fiberG }
        if let sugarG = body.sugarG { goals.sugarG = sugarG }
        if let sodiumMg = body.sodiumMg { goals.sodiumMg = sodiumMg }
        if let waterMl = body.waterMl { goals.waterMl = waterMl }

        try await goals.save(on: req.db)

        return GoalsResponse(
            calories: goals.calories,
            proteinG: goals.proteinG,
            carbsG: goals.carbsG,
            fatG: goals.fatG,
            fiberG: goals.fiberG,
            sugarG: goals.sugarG,
            sodiumMg: goals.sodiumMg,
            waterMl: goals.waterMl
        )
    }
}
