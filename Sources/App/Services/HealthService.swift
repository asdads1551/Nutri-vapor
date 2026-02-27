import Vapor
import Fluent

/// Business logic for health-related operations
struct HealthService {
    let db: Database

    /// Analyze weekly health trends for a user
    func weeklyAnalysis(userID: UUID) async throws -> (avgSteps: Int?, avgSleep: Double?, weightTrend: String) {
        let calendar = Calendar.taipei
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let logs = try await HealthSyncLog.query(on: db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= weekAgo)
            .sort(\.$date, .ascending)
            .all()

        let steps = logs.compactMap(\.steps)
        let avgSteps = steps.isEmpty ? nil : steps.reduce(0, +) / steps.count

        let sleepData = logs.compactMap(\.sleepHours)
        let avgSleep = sleepData.isEmpty ? nil : sleepData.reduce(0, +) / Double(sleepData.count)

        let weights = logs.compactMap(\.weightKg)
        let weightTrend: String
        if weights.count >= 2 {
            let diff = weights.last! - weights.first!
            if diff > 0.5 { weightTrend = "上升" }
            else if diff < -0.5 { weightTrend = "下降" }
            else { weightTrend = "穩定" }
        } else {
            weightTrend = "數據不足"
        }

        return (avgSteps, avgSleep, weightTrend)
    }
}
