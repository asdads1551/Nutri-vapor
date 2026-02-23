import Vapor

func routes(_ app: Application) throws {
    // Health check
    app.get("health") { req in
        ["status": "ok"]
    }

    // API v1 routes
    let api = app.grouped("api", "v1")

    // Public health check
    api.get("health") { req in
        ["status": "ok", "version": "1.0.0"]
    }

    // Firebase Auth protected routes (for register/login)
    let firebaseAuth = api.grouped(FirebaseAuthMiddleware())
    try firebaseAuth.register(collection: AuthController())

    // JWT Auth protected routes (for all business APIs)
    let jwtAuth = api.grouped(JWTAuthMiddleware())
    try jwtAuth.register(collection: UserController())
    try jwtAuth.register(collection: NutritionController())
    try jwtAuth.register(collection: RecipeController())
    try jwtAuth.register(collection: HealthController())
    try jwtAuth.register(collection: NotificationController())
}
