import Vapor
import Fluent

struct NotificationController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let notifications = routes.grouped("notifications")
        notifications.get("settings", use: getSettings)
        notifications.put("settings", use: updateSettings)
        notifications.get("history", use: getHistory)
    }

    // MARK: - Notification Settings DTO
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

    struct UpdateNotificationSettingsRequest: Content {
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
    }

    // MARK: - GET /notifications/settings
    /// Note: In the hybrid architecture, notification settings are stored in Firestore.
    /// This endpoint acts as a proxy/fallback. The iOS app can read from Firestore directly.
    @Sendable
    func getSettings(req: Request) async throws -> NotificationSettingsResponse {
        _ = try req.authenticatedUserID
        // Default settings — in production, read from Firestore or local DB
        return NotificationSettingsResponse(
            mealRemind: true,
            waterRemind: true,
            nutritionAlert: true,
            weeklyReport: true,
            quietHoursStart: "22:00",
            quietHoursEnd: "07:00"
        )
    }

    // MARK: - PUT /notifications/settings
    @Sendable
    func updateSettings(req: Request) async throws -> NotificationSettingsResponse {
        _ = try req.authenticatedUserID
        let body = try req.content.decode(UpdateNotificationSettingsRequest.self)

        // TODO: Save to Firestore or local DB
        return NotificationSettingsResponse(
            mealRemind: body.mealRemind ?? true,
            waterRemind: body.waterRemind ?? true,
            nutritionAlert: body.nutritionAlert ?? true,
            weeklyReport: body.weeklyReport ?? true,
            quietHoursStart: body.quietHoursStart ?? "22:00",
            quietHoursEnd: body.quietHoursEnd ?? "07:00"
        )
    }

    // MARK: - GET /notifications/history
    @Sendable
    func getHistory(req: Request) async throws -> [PushLog] {
        let userID = try req.authenticatedUserID
        return try await PushLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$sentAt, .descending)
            .limit(50)
            .all()
    }
}
