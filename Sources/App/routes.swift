import Vapor
import Fluent
import SQLKit

func routes(_ app: Application) throws {
    // Health check with DB connectivity verification (#14)
    app.get("health") { req async throws -> HealthCheckResponse in
        var dbStatus = "disconnected"
        do {
            if let sqlDB = req.db as? any SQLDatabase {
                _ = try await sqlDB.raw("SELECT 1").all()
            }
            dbStatus = "connected"
        } catch {
            req.logger.error("Health check DB probe failed: \(error)")
        }
        return HealthCheckResponse(
            status: dbStatus == "connected" ? "ok" : "degraded",
            version: APIConstants.version,
            database: dbStatus
        )
    }

    // API v1 routes
    let api = app.grouped("api", "v1")

    // Public health check
    api.get("health") { req async throws -> HealthCheckResponse in
        var dbStatus = "disconnected"
        do {
            if let sqlDB = req.db as? any SQLDatabase {
                _ = try await sqlDB.raw("SELECT 1").all()
            }
            dbStatus = "connected"
        } catch {
            req.logger.error("Health check DB probe failed: \(error)")
        }
        return HealthCheckResponse(
            status: dbStatus == "connected" ? "ok" : "degraded",
            version: APIConstants.version,
            database: dbStatus
        )
    }

    // Rate limiters (#2)
    let authRateLimit = RateLimitMiddleware(
        maxRequests: APIConstants.authRateLimit,
        windowSeconds: 60
    )
    let generalRateLimit = RateLimitMiddleware(
        maxRequests: APIConstants.generalRateLimit,
        windowSeconds: 60
    )

    // Auth routes — rate limited, Firebase token verified in controller from body
    let authRoutes = api.grouped(authRateLimit)
    try authRoutes.register(collection: AuthController())

    // JWT Auth protected routes (for all business APIs) — with general rate limiting
    let jwtAuth = api.grouped(generalRateLimit).grouped(JWTAuthMiddleware())
    try jwtAuth.register(collection: UserController())
    try jwtAuth.register(collection: NutritionController())
    try jwtAuth.register(collection: RecipeController())
    try jwtAuth.register(collection: HealthController())
    try jwtAuth.register(collection: NotificationController())
}

// MARK: - Health Check Response
struct HealthCheckResponse: Content {
    let status: String
    let version: String
    let database: String
}
