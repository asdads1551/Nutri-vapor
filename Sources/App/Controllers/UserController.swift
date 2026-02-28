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

        let profile = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()

        return UserDetailResponse(
            id: user.id!.uuidString,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            avatarUrl: profile?.avatarURL,
            dateCreated: user.createdAt,
            lastLoginDate: user.lastLoginDate
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

        // Update avatarUrl on UserProfile if provided
        if let avatarUrl = body.avatarUrl {
            let profile: UserProfile
            if let existing = try await UserProfile.query(on: req.db)
                .filter(\.$user.$id == userID)
                .first() {
                profile = existing
            } else {
                profile = UserProfile(userID: userID)
            }
            profile.avatarURL = avatarUrl
            try await profile.save(on: req.db)
        }

        let profile = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()

        return UserDetailResponse(
            id: user.id!.uuidString,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            avatarUrl: profile?.avatarURL,
            dateCreated: user.createdAt,
            lastLoginDate: user.lastLoginDate
        )
    }

    // MARK: - GET /users/me/profile
    @Sendable
    func getProfile(req: Request) async throws -> ProfileResponse {
        let userID = try req.authenticatedUserID

        let profile = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()

        let preference = try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()

        return ProfileResponse(
            dietType: profile?.dietType?.rawValue,
            allergens: profile?.allergies,
            cuisinePreferences: profile?.cuisinePreferences,
            preferHighProtein: profile?.preferHighProtein ?? false,
            preferLowCarb: profile?.preferLowCarb ?? false,
            preferLowSodium: profile?.preferLowSodium ?? false,
            preferLowSugar: profile?.preferLowSugar ?? false,
            avoidSpicy: profile?.avoidSpicy ?? false,
            language: preference?.language,
            theme: preference?.theme,
            onboardingCompleted: preference?.onboardingCompleted ?? false
        )
    }

    // MARK: - PUT /users/me/profile
    @Sendable
    func updateProfile(req: Request) async throws -> ProfileResponse {
        let userID = try req.authenticatedUserID
        try UpdateProfileRequest.validate(content: req)
        let body = try req.content.decode(UpdateProfileRequest.self)

        // Update dietary fields on UserProfile
        let profile: UserProfile
        if let existing = try await UserProfile.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() {
            profile = existing
        } else {
            profile = UserProfile(userID: userID)
        }

        if let dietType = body.dietType {
            profile.dietType = DietTypeDB(rawValue: dietType) ?? DietTypeDB(chinese: dietType)
        }
        if let allergens = body.allergens { profile.allergies = allergens }
        if let cuisinePreferences = body.cuisinePreferences { profile.cuisinePreferences = cuisinePreferences }
        if let preferHighProtein = body.preferHighProtein { profile.preferHighProtein = preferHighProtein }
        if let preferLowCarb = body.preferLowCarb { profile.preferLowCarb = preferLowCarb }
        if let preferLowSodium = body.preferLowSodium { profile.preferLowSodium = preferLowSodium }
        if let preferLowSugar = body.preferLowSugar { profile.preferLowSugar = preferLowSugar }
        if let avoidSpicy = body.avoidSpicy { profile.avoidSpicy = avoidSpicy }

        try await profile.save(on: req.db)

        // Update app settings on UserPreference
        let preference: UserPreference
        if let existing = try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() {
            preference = existing
        } else {
            preference = UserPreference(userID: userID)
        }

        if let language = body.language { preference.language = language }
        if let theme = body.theme { preference.theme = theme }
        if let onboardingCompleted = body.onboardingCompleted { preference.onboardingCompleted = onboardingCompleted }

        try await preference.save(on: req.db)

        return ProfileResponse(
            dietType: profile.dietType?.rawValue,
            allergens: profile.allergies,
            cuisinePreferences: profile.cuisinePreferences,
            preferHighProtein: profile.preferHighProtein,
            preferLowCarb: profile.preferLowCarb,
            preferLowSodium: profile.preferLowSodium,
            preferLowSugar: profile.preferLowSugar,
            avoidSpicy: profile.avoidSpicy,
            language: preference.language,
            theme: preference.theme,
            onboardingCompleted: preference.onboardingCompleted
        )
    }

    // MARK: - GET /users/me/goals
    @Sendable
    func getGoals(req: Request) async throws -> GoalsResponse {
        let userID = try req.authenticatedUserID
        let goal = try await NutritionGoal.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$effectiveDate, .descending)
            .first()

        return GoalsResponse(
            calorieGoal: Double(goal?.calories ?? 2000),
            proteinGoal: goal?.proteinG ?? 60,
            carbsGoal: goal?.carbsG ?? 250,
            fatGoal: goal?.fatG ?? 65,
            fiberGoal: goal?.fiberG ?? 25,
            sugarGoal: goal?.sugarG ?? 50,
            sodiumGoal: goal?.sodiumMg ?? 2300
        )
    }

    // MARK: - PUT /users/me/goals
    @Sendable
    func updateGoals(req: Request) async throws -> GoalsResponse {
        let userID = try req.authenticatedUserID
        try UpdateGoalsRequest.validate(content: req)
        let body = try req.content.decode(UpdateGoalsRequest.self)

        let goal: NutritionGoal
        if let existing = try await NutritionGoal.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$effectiveDate, .descending)
            .first() {
            goal = existing
        } else {
            goal = NutritionGoal(userID: userID)
        }

        if let v = body.calorieGoal { goal.calories = Int(v) }
        if let v = body.proteinGoal { goal.proteinG = v }
        if let v = body.carbsGoal { goal.carbsG = v }
        if let v = body.fatGoal { goal.fatG = v }
        if let v = body.fiberGoal { goal.fiberG = v }
        if let v = body.sugarGoal { goal.sugarG = v }
        if let v = body.sodiumGoal { goal.sodiumMg = v }

        try await goal.save(on: req.db)

        return GoalsResponse(
            calorieGoal: Double(goal.calories),
            proteinGoal: goal.proteinG,
            carbsGoal: goal.carbsG,
            fatGoal: goal.fatG,
            fiberGoal: goal.fiberG,
            sugarGoal: goal.sugarG,
            sodiumGoal: goal.sodiumMg
        )
    }
}
