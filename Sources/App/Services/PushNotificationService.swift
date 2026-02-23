import Vapor
import Fluent

/// Service for sending push notifications via Firebase Cloud Messaging (FCM).
/// In the hybrid architecture, this server triggers intelligent push notifications
/// based on user nutrition data analysis.
struct PushNotificationService {
    let app: Application
    let db: Database

    /// Check and send nutrition-related push notifications
    /// Called periodically (e.g., via a scheduled job)
    func checkAndSendNotifications() async throws {
        // TODO: Implement scheduled notification checks
        // 1. Find users who haven't logged food by meal time
        // 2. Find users with low protein/fiber intake
        // 3. Send appropriate reminders via FCM

        app.logger.info("Push notification check triggered")
    }

    /// Send a push notification to a user via FCM
    func sendNotification(
        userID: UUID,
        title: String,
        body: String,
        type: PushType
    ) async throws {
        // TODO: Implement FCM REST API call
        // POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send
        // Requires: Firebase service account + OAuth 2.0 token

        // Log the push attempt
        let log = PushLog()
        log.$user.id = userID
        log.type = type
        log.title = title
        log.body = body
        log.status = .sent
        log.sentAt = Date()
        try await log.save(on: db)

        app.logger.info("Push notification sent to user \(userID): \(title)")
    }

    /// Send meal reminder
    func sendMealReminder(userID: UUID, mealType: MealTypeDB) async throws {
        let title = "用餐提醒"
        let body: String
        switch mealType {
        case .breakfast: body = "早安！別忘了記錄今天的早餐 🌅"
        case .lunch: body = "午餐時間到了！記得記錄你的午餐 ☀️"
        case .dinner: body = "晚餐時間！記錄你的晚餐吧 🌙"
        case .snack: body = "下午茶時間～記錄你的點心 🍪"
        }

        try await sendNotification(
            userID: userID,
            title: title,
            body: body,
            type: .mealRemind
        )
    }

    /// Send nutrition alert when intake is low
    func sendNutritionAlert(userID: UUID, nutrient: String, currentPct: Int) async throws {
        try await sendNotification(
            userID: userID,
            title: "營養提醒",
            body: "今日\(nutrient)攝取只有 \(currentPct)%，建議適量補充",
            type: .nutritionAlert
        )
    }
}
