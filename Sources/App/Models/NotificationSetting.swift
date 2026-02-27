import Fluent
import Vapor

final class NotificationSetting: Model, Content, @unchecked Sendable {
    static let schema = "notification_settings"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "meal_remind") var mealRemind: Bool
    @Field(key: "water_remind") var waterRemind: Bool
    @Field(key: "nutrition_alert") var nutritionAlert: Bool
    @Field(key: "weekly_report") var weeklyReport: Bool
    @Field(key: "quiet_hours_start") var quietHoursStart: String?
    @Field(key: "quiet_hours_end") var quietHoursEnd: String?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        mealRemind: Bool = true,
        waterRemind: Bool = true,
        nutritionAlert: Bool = true,
        weeklyReport: Bool = true,
        quietHoursStart: String? = "22:00",
        quietHoursEnd: String? = "07:00"
    ) {
        self.id = id
        self.$user.id = userID
        self.mealRemind = mealRemind
        self.waterRemind = waterRemind
        self.nutritionAlert = nutritionAlert
        self.weeklyReport = weeklyReport
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }
}
