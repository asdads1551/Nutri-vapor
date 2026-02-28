import Vapor
import Fluent
import FluentPostgresDriver
import JWT

func configure(_ app: Application) async throws {
    // MARK: - Environment Safety (#19)
    if app.environment != .development {
        guard let secret = Environment.get("JWT_SECRET"), secret.count >= 32 else {
            fatalError("JWT_SECRET environment variable is required (min 32 chars) in non-development environments")
        }
        guard Environment.get("DATABASE_URL") != nil || Environment.get("DB_PASSWORD") != nil else {
            fatalError("DATABASE_URL or DB_PASSWORD environment variable is required in non-development environments")
        }
    }

    // MARK: - Database Configuration
    if let databaseURL = Environment.get("DATABASE_URL") {
        try app.databases.use(
            .postgres(url: databaseURL),
            as: .psql
        )
    } else {
        let hostname = Environment.get("DB_HOSTNAME") ?? "localhost"
        let port = Environment.get("DB_PORT").flatMap(Int.init) ?? 5432
        let username = Environment.get("DB_USERNAME") ?? "nutri"
        let password = Environment.get("DB_PASSWORD") ?? "nutri_dev"
        let database = Environment.get("DB_NAME") ?? "nutri_db"

        let config = SQLPostgresConfiguration(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: app.environment == .development ? .disable : .prefer(try .init(configuration: .clientDefault))
        )
        app.databases.use(.postgres(configuration: config), as: .psql)
    }

    // MARK: - JWT Configuration (#7)
    let jwtSecret = Environment.get("JWT_SECRET") ?? "dev-secret-change-in-production"
    await app.jwt.keys.add(hmac: .init(from: Data(jwtSecret.utf8)), digestAlgorithm: .sha256)

    // MARK: - Server Configuration (#15 graceful shutdown / compression)
    app.http.server.configuration.requestDecompression = .enabled
    app.http.server.configuration.responseCompression = .enabled

    // MARK: - Middleware
    // CORS — whitelist in production, permissive in development (#6)
    let allowedOrigin: CORSMiddleware.AllowOriginSetting
    if let corsOrigin = Environment.get("CORS_ALLOWED_ORIGIN") {
        allowedOrigin = .custom(corsOrigin)
    } else if app.environment == .production {
        allowedOrigin = .none
    } else {
        allowedOrigin = .all
    }
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: allowedOrigin,
        allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )))

    // MARK: - Migrations
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateUserProfiles())
    app.migrations.add(CreateNutritionGoals())
    app.migrations.add(CreateFoodEntries())
    app.migrations.add(CreateDailyNutritionSummary())
    app.migrations.add(CreateRecipes())
    app.migrations.add(CreateRecipeTags())
    app.migrations.add(CreateRecipeIngredients())
    app.migrations.add(CreateUserFavorites())
    app.migrations.add(CreateHealthSyncLogs())
    app.migrations.add(CreatePushLogs())
    app.migrations.add(CreateNotificationSettings())

    // Phase 2: Schema evolution migrations (frontend-backend alignment)
    app.migrations.add(AddLastLoginToUsers())
    app.migrations.add(AddDietaryPrefsToUserProfiles())
    app.migrations.add(CreateUserPreferences())
    app.migrations.add(AddMicronutrientsToDailySummary())
    app.migrations.add(AddRecipeAuthorAndIconFields())
    app.migrations.add(CreateRecipeAllergens())
    app.migrations.add(RenameHealthActiveCalToActiveCalories())

    // Phase 3: Soft delete support for all models
    app.migrations.add(AddSoftDeleteToAllModels())

    // MARK: - Routes
    try routes(app)
}
