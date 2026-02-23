import Vapor
import Fluent

struct HealthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let health = routes.grouped("health")
        health.post("sync", use: syncHealth)
        health.get("summary", use: healthSummary)
        health.get("trends", use: healthTrends)
        health.get("report", "weekly", use: weeklyReport)
    }

    // MARK: - POST /health/sync
    @Sendable
    func syncHealth(req: Request) async throws -> SuccessResponse {
        let userID = try req.authenticatedUserID
        let body = try req.content.decode(HealthSyncRequest.self)

        // Upsert health sync log
        let existing = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date == body.date)
            .first()

        if let log = existing {
            if let steps = body.steps { log.steps = steps }
            if let activeCal = body.activeCal { log.activeCal = activeCal }
            if let weightKg = body.weightKg { log.weightKg = weightKg }
            if let heartRate = body.heartRate { log.heartRate = heartRate }
            if let sleepHours = body.sleepHours { log.sleepHours = sleepHours }
            try await log.save(on: req.db)
        } else {
            let log = HealthSyncLog()
            log.$user.id = userID
            log.date = body.date
            log.steps = body.steps
            log.activeCal = body.activeCal
            log.weightKg = body.weightKg
            log.heartRate = body.heartRate
            log.sleepHours = body.sleepHours
            try await log.save(on: req.db)
        }

        return SuccessResponse(message: "Health data synced")
    }

    // MARK: - GET /health/summary
    @Sendable
    func healthSummary(req: Request) async throws -> HealthSummaryResponse {
        let userID = try req.authenticatedUserID
        let dateStr = req.query[String.self, at: "date"] ?? {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else {
            throw Abort(.badRequest, reason: "Invalid date format")
        }

        let log = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date == date)
            .first()

        return HealthSummaryResponse(
            date: dateStr,
            steps: log?.steps,
            activeCal: log?.activeCal,
            weightKg: log?.weightKg,
            heartRate: log?.heartRate,
            sleepHours: log?.sleepHours,
            nutritionScore: nil
        )
    }

    // MARK: - GET /health/trends
    @Sendable
    func healthTrends(req: Request) async throws -> HealthTrendResponse {
        let userID = try req.authenticatedUserID
        let metric = req.query[String.self, at: "metric"] ?? "steps"
        let range = req.query[String.self, at: "range"] ?? "30d"
        let days = Int(range.replacingOccurrences(of: "d", with: "")) ?? 30

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!

        let logs = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= startDate)
            .sort(\.$date, .ascending)
            .all()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let data: [TrendDataPoint] = logs.compactMap { log in
            let value: Double?
            switch metric {
            case "steps": value = log.steps.map(Double.init)
            case "weight": value = log.weightKg
            case "active_cal": value = log.activeCal
            case "heart_rate": value = log.heartRate.map(Double.init)
            case "sleep": value = log.sleepHours
            default: value = log.steps.map(Double.init)
            }
            guard let v = value else { return nil }
            return TrendDataPoint(date: formatter.string(from: log.date), value: v)
        }

        let average = data.isEmpty ? 0 : data.reduce(0) { $0 + $1.value } / Double(data.count)

        return HealthTrendResponse(
            metric: metric,
            range: range,
            data: data,
            average: average
        )
    }

    // MARK: - GET /health/report/weekly
    @Sendable
    func weeklyReport(req: Request) async throws -> WeeklyReportResponse {
        let userID = try req.authenticatedUserID
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Get nutrition data
        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= weekAgo)
            .all()

        let totalCalories = entries.reduce(0.0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0.0) { $0 + $1.proteinG }
        let avgCalories = entries.isEmpty ? 0 : totalCalories / 7.0
        let avgProtein = entries.isEmpty ? 0 : totalProtein / 7.0

        // Get health data
        let logs = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= weekAgo)
            .all()

        let avgSteps = logs.compactMap(\.steps).isEmpty ? nil :
            logs.compactMap(\.steps).reduce(0, +) / max(1, logs.compactMap(\.steps).count)

        var highlights: [String] = []
        if avgProtein > 50 { highlights.append("蛋白質攝取充足 ✓") }
        if avgCalories > 0 { highlights.append("本週平均熱量: \(Int(avgCalories)) kcal") }

        return WeeklyReportResponse(
            weekStart: formatter.string(from: weekAgo),
            weekEnd: formatter.string(from: today),
            avgCalories: avgCalories,
            avgProtein: avgProtein,
            avgSteps: avgSteps,
            daysGoalMet: 0,
            nutritionScore: 0,
            highlights: highlights
        )
    }
}
