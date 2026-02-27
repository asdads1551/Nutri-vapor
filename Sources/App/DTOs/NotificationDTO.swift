import Vapor

// MARK: - Notification Settings Response
struct NotificationSettingsResponse: Content {
    let mealRemind: Bool
    let waterRemind: Bool
    let nutritionAlert: Bool
    let weeklyReport: Bool
    let quietHoursStart: String?
    let quietHoursEnd: String?

    enum CodingKeys: String, CodingKey {
        case mealRemind = "meal_remind"
        case waterRemind = "water_remind"
        case nutritionAlert = "nutrition_alert"
        case weeklyReport = "weekly_report"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
    }
}

// MARK: - Update Notification Settings Request
struct UpdateNotificationSettingsRequest: Content, Validatable {
    let mealRemind: Bool?
    let waterRemind: Bool?
    let nutritionAlert: Bool?
    let weeklyReport: Bool?
    let quietHoursStart: String?
    let quietHoursEnd: String?

    enum CodingKeys: String, CodingKey {
        case mealRemind = "meal_remind"
        case waterRemind = "water_remind"
        case nutritionAlert = "nutrition_alert"
        case weeklyReport = "weekly_report"
        case quietHoursStart = "quiet_hours_start"
        case quietHoursEnd = "quiet_hours_end"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("quiet_hours_start", as: String?.self, required: false, is: .nil || .pattern(#"^\d{2}:\d{2}$"#))
        validations.add("quiet_hours_end", as: String?.self, required: false, is: .nil || .pattern(#"^\d{2}:\d{2}$"#))
    }
}

// MARK: - PushLog Response DTO
struct PushLogResponse: Content {
    let type: String
    let title: String
    let body: String
    let status: String
    let sentAt: Date
    let clickedAt: Date?

    enum CodingKeys: String, CodingKey {
        case type, title, body, status
        case sentAt = "sent_at"
        case clickedAt = "clicked_at"
    }
}
