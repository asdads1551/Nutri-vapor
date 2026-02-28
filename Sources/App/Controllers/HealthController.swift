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
        try HealthSyncRequest.validate(content: req)
        let body = try req.content.decode(HealthSyncRequest.self)

        // Parse date string to Date
        guard let date = DateFormatter.yyyyMMdd.date(from: body.date) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use yyyy-MM-dd")
        }

        let existing = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date == date)
            .first()

        if let log = existing {
            if let steps = body.steps { log.steps = steps }
            if let activeCalories = body.activeCalories { log.activeCalories = activeCalories }
            if let weight = body.weight { log.weightKg = weight }
            if let heartRate = body.heartRate { log.heartRate = heartRate }
            if let sleepHours = body.sleepHours { log.sleepHours = sleepHours }
            // Ignore stepsChange and weightChange (derived values, not persisted per 3NF)
            try await log.save(on: req.db)
        } else {
            let log = HealthSyncLog()
            log.$user.id = userID
            log.date = date
            log.steps = body.steps
            log.activeCalories = body.activeCalories
            log.weightKg = body.weight
            log.heartRate = body.heartRate
            log.sleepHours = body.sleepHours
            // Ignore stepsChange and weightChange (derived values, not persisted per 3NF)
            try await log.save(on: req.db)
        }

        return SuccessResponse(message: "Health data synced")
    }

    // MARK: - GET /health/summary
    @Sendable
    func healthSummary(req: Request) async throws -> [HealthSummaryResponse] {
        let userID = try req.authenticatedUserID

        let fromStr = req.query[String.self, at: "from"]
        let toStr = req.query[String.self, at: "to"]

        // If neither from nor to is provided, default to single day (today)
        let fromDate: Date
        let toDate: Date

        if let f = fromStr, let fDate = DateFormatter.yyyyMMdd.date(from: f) {
            fromDate = fDate
        } else {
            fromDate = Calendar.taipei.startOfDay(for: Date())
        }

        if let t = toStr, let tDate = DateFormatter.yyyyMMdd.date(from: t) {
            toDate = tDate
        } else {
            toDate = fromDate
        }

        // Query range: from fromDate to end of toDate
        let endDate = Calendar.taipei.date(byAdding: .day, value: 1, to: toDate)!

        let logs = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= fromDate)
            .filter(\.$date < endDate)
            .sort(\.$date, .ascending)
            .all()

        // For stepsChange, we need the previous day's data for each log
        // Fetch one day before fromDate to compute stepsChange for the first day
        let dayBeforeFrom = Calendar.taipei.date(byAdding: .day, value: -1, to: fromDate)!
        let previousDayLog = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= dayBeforeFrom)
            .filter(\.$date < fromDate)
            .first()

        var results: [HealthSummaryResponse] = []
        var previousSteps: Int? = previousDayLog?.steps

        for log in logs {
            let dateStr = DateFormatter.yyyyMMdd.string(from: log.date)

            // Compute stepsChange on the fly
            let stepsChange: Double?
            if let current = log.steps, let prev = previousSteps, prev > 0 {
                stepsChange = Double(current - prev) / Double(prev) * 100.0
            } else {
                stepsChange = nil
            }

            results.append(HealthSummaryResponse(
                date: dateStr,
                steps: log.steps,
                stepsChange: stepsChange,
                activeCalories: log.activeCalories,
                weight: log.weightKg,
                heartRate: log.heartRate,
                sleepHours: log.sleepHours
            ))

            previousSteps = log.steps
        }

        // If no logs found for single-day query, return empty entry
        if results.isEmpty {
            let dateStr = DateFormatter.yyyyMMdd.string(from: fromDate)
            results.append(HealthSummaryResponse(
                date: dateStr,
                steps: nil,
                stepsChange: nil,
                activeCalories: nil,
                weight: nil,
                heartRate: nil,
                sleepHours: nil
            ))
        }

        return results
    }

    // MARK: - GET /health/trends
    @Sendable
    func healthTrends(req: Request) async throws -> HealthTrendResponse {
        let userID = try req.authenticatedUserID
        let metric = req.query[String.self, at: "metric"] ?? "steps"
        let range = req.query[String.self, at: "range"] ?? "30d"
        let days = max(1, min(Int(range.replacingOccurrences(of: "d", with: "")) ?? 30, 365))

        let calendar = Calendar.taipei
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!

        let logs = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= startDate)
            .sort(\.$date, .ascending)
            .all()

        let data: [TrendDataPoint] = logs.compactMap { log in
            let value: Double?
            switch metric {
            case "steps": value = log.steps.map(Double.init)
            case "weight": value = log.weightKg
            case "activeCalories", "active_calories": value = log.activeCalories
            case "heart_rate": value = log.heartRate.map(Double.init)
            case "sleep": value = log.sleepHours
            default: value = log.steps.map(Double.init)
            }
            guard let v = value else { return nil }
            return TrendDataPoint(date: DateFormatter.yyyyMMdd.string(from: log.date), value: v)
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
        let calendar = Calendar.taipei
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= weekAgo)
            .all()

        let totalCalories = entries.reduce(0.0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0.0) { $0 + $1.proteinG }
        let avgCalories = entries.isEmpty ? 0 : totalCalories / 7.0
        let avgProtein = entries.isEmpty ? 0 : totalProtein / 7.0

        let logs = try await HealthSyncLog.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= weekAgo)
            .all()

        let stepValues = logs.compactMap(\.steps)
        let avgSteps = stepValues.isEmpty ? nil : stepValues.reduce(0, +) / stepValues.count

        var highlights: [String] = []
        if avgProtein > 50 { highlights.append("蛋白質攝取充足") }
        if avgCalories > 0 { highlights.append("本週平均熱量: \(Int(avgCalories)) kcal") }

        return WeeklyReportResponse(
            weekStart: DateFormatter.yyyyMMdd.string(from: weekAgo),
            weekEnd: DateFormatter.yyyyMMdd.string(from: today),
            avgCalories: avgCalories,
            avgProtein: avgProtein,
            avgSteps: avgSteps,
            daysGoalMet: 0,
            nutritionScore: 0,
            highlights: highlights
        )
    }
}
