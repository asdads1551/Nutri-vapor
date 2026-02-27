import Vapor
import Fluent
import FluentPostgresDriver
import JWT

func configure(_ app: Application) async throws {
    // MARK: - Environment Safety (#19)
    if app.environment == .production {
        guard Environment.get("JWT_SECRET") != nil else {
            fatalError("JWT_SECRET environment variable is required in production")
        }
        guard Environment.get("DATABASE_URL") != nil || Environment.get("DB_PASSWORD") != nil else {
            fatalError("DATABASE_URL or DB_PASSWORD environment variable is required in production")
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

        let tlsConfig: SQLPostgresConfiguration.TLS = app.environment == .production ? .require(try .init(configuration: .clientDefault)) : .disable
        if app.environment != .production {
            app.logger.warning("Database TLS disabled in development. Enable TLS for production.")
        }
        let config = SQLPostgresConfiguration(
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tlsConfig
        )
        app.databases.use(.postgres(configuration: config), as: .psql)
    }

    // MARK: - JWT Configuration (#7)
    let jwtSecret: String
    if let envSecret = Environment.get("JWT_SECRET") {
        jwtSecret = envSecret
    } else if app.environment == .production {
        fatalError("JWT_SECRET environment variable is required in production")
    } else {
        jwtSecret = "dev-secret-DO-NOT-USE-IN-PRODUCTION"
        app.logger.warning("Using development JWT secret. Set JWT_SECRET for production.")
    }
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
        app.logger.warning("CORS_ALLOWED_ORIGIN not set — all cross-origin requests blocked in production. Set this to your frontend domain.")
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
    app.migrations.add(AddMissingIndexes())

    // MARK: - Routes
    try routes(app)
}
