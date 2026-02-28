import Vapor
import Fluent

struct NotificationController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let notifications = routes.grouped("notifications")
        notifications.get("settings", use: getSettings)
        notifications.put("settings", use: updateSettings)
        notifications.get("history", use: getHistory)
    }

    // MARK: - Notification Settings DTO (frontend-aligned, no weeklyReport)
    struct NotificationSettingsResponse: Content {
        let mealRemind: Bool
        let waterRemind: Bool
        let nutritionAlert: Bool
        let quietHoursStart: String
        let quietHoursEnd: String

        enum CodingKeys: String, CodingKey {
            case mealRemind = "meal_remind"
            case waterRemind = "water_remind"
            case nutritionAlert = "nutrition_alert"
            case quietHoursStart = "quiet_hours_start"
            case quietHoursEnd = "quiet_hours_end"
        }
    }

    struct UpdateNotificationSettingsRequest: Content {
        let mealRemind: Bool
        let waterRemind: Bool
        let nutritionAlert: Bool
        let quietHoursStart: String
        let quietHoursEnd: String

        enum CodingKeys: String, CodingKey {
            case mealRemind = "meal_remind"
            case waterRemind = "water_remind"
            case nutritionAlert = "nutrition_alert"
            case quietHoursStart = "quiet_hours_start"
            case quietHoursEnd = "quiet_hours_end"
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

    // MARK: - GET /notifications/settings
    @Sendable
    func getSettings(req: Request) async throws -> NotificationSettingsResponse {
        let userID = try req.authenticatedUserID

        let settings = try await NotificationSetting.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()

        return NotificationSettingsResponse(
            mealRemind: settings?.mealRemind ?? true,
            waterRemind: settings?.waterRemind ?? true,
            nutritionAlert: settings?.nutritionAlert ?? true,
            quietHoursStart: settings?.quietHoursStart ?? "22:00",
            quietHoursEnd: settings?.quietHoursEnd ?? "07:00"
        )
    }

    // MARK: - PUT /notifications/settings
    @Sendable
    func updateSettings(req: Request) async throws -> NotificationSettingsResponse {
        let userID = try req.authenticatedUserID
        let body = try req.content.decode(UpdateNotificationSettingsRequest.self)

        let settings: NotificationSetting
        if let existing = try await NotificationSetting.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first() {
            settings = existing
        } else {
            settings = NotificationSetting(userID: userID)
        }

        settings.mealRemind = body.mealRemind
        settings.waterRemind = body.waterRemind
        settings.nutritionAlert = body.nutritionAlert
        // weeklyReport not exposed in DTO but still written to DB with default true
        settings.weeklyReport = true
        settings.quietHoursStart = body.quietHoursStart
        settings.quietHoursEnd = body.quietHoursEnd

        try await settings.save(on: req.db)

        return NotificationSettingsResponse(
            mealRemind: settings.mealRemind,
            waterRemind: settings.waterRemind,
            nutritionAlert: settings.nutritionAlert,
            quietHoursStart: settings.quietHoursStart ?? "22:00",
            quietHoursEnd: settings.quietHoursEnd ?? "07:00"
        )
    }

    // MARK: - GET /notifications/history
    @Sendable
    func getHistory(req: Request) async throws -> [PushLogResponse] {
        let userID = try req.authenticatedUserID
        let page = max(1, req.query[Int.self, at: "page"] ?? 1)
        let limit = min(req.query[Int.self, at: "limit"] ?? 20, 50)

        let logs = try await PushLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$sentAt, .descending)
            .range(lower: (page - 1) * limit, upper: page * limit)
            .all()

        return logs.map { log in
            PushLogResponse(
                type: log.type.rawValue,
                title: log.title,
                body: log.body,
                status: log.status.rawValue,
                sentAt: log.sentAt,
                clickedAt: log.clickedAt
            )
        }
    }
}
