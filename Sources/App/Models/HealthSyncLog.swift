import Fluent
import Vapor

final class HealthSyncLog: Model, Content, @unchecked Sendable {
    static let schema = "health_sync_logs"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "date") var date: Date
    @Field(key: "steps") var steps: Int?
    @Field(key: "active_calories") var activeCalories: Double?
    @Field(key: "weight_kg") var weightKg: Double?
    @Field(key: "heart_rate") var heartRate: Int?
    @Field(key: "sleep_hours") var sleepHours: Double?
    @Timestamp(key: "synced_at", on: .create) var syncedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete) var deletedAt: Date?

    init() {}
}
