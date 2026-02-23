import Vapor
import Fluent
import FluentPostgresDriver

func configure(_ app: Application) async throws {
    // MARK: - Database Configuration
    if let databaseURL = Environment.get("DATABASE_URL") {
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.certificateVerification = .none

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
            tls: .disable
        )
        app.databases.use(.postgres(configuration: config), as: .psql)
    }

    // MARK: - Middleware
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
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

    // MARK: - Routes
    try routes(app)
}
