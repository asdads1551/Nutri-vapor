import Vapor

enum APIConstants {
    static let version = "1.0.0"
    static let apiPrefix = "api"
    static let apiVersion = "v1"

    // JWT
    static let jwtExpirationMinutes = 15
    static let jwtRefreshExpirationDays = 30

    // Rate Limiting
    static let authRateLimit = 5       // requests per minute
    static let generalRateLimit = 100  // requests per minute per user

    // Pagination
    static let defaultPageSize = 20
    static let maxPageSize = 100

    // Sync
    static let maxSyncBatchSize = 100

    // Firebase
    static let firebaseProjectId = Environment.get("FIREBASE_PROJECT_ID") ?? "nutri-app-c0d75"
    static let googleCertsURL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
    static let googleJWKSURL = "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"
}
