import Vapor

// MARK: - Health Sync Request
struct HealthSyncRequest: Content {
    let date: Date
    let steps: Int?
    let activeCal: Double?
    let weightKg: Double?
    let heartRate: Int?
    let sleepHours: Double?

    enum CodingKeys: String, CodingKey {
        case date, steps
        case activeCal = "active_cal"
        case weightKg = "weight_kg"
        case heartRate = "heart_rate"
        case sleepHours = "sleep_hours"
    }
}

// MARK: - Health Summary Response
struct HealthSummaryResponse: Content {
    let date: String
    let steps: Int?
    let activeCal: Double?
    let weightKg: Double?
    let heartRate: Int?
    let sleepHours: Double?
    let nutritionScore: Int?

    enum CodingKeys: String, CodingKey {
        case date, steps
        case activeCal = "active_cal"
        case weightKg = "weight_kg"
        case heartRate = "heart_rate"
        case sleepHours = "sleep_hours"
        case nutritionScore = "nutrition_score"
    }
}

// MARK: - Health Trend Response
struct HealthTrendResponse: Content {
    let metric: String
    let range: String
    let data: [TrendDataPoint]
    let average: Double
}

// MARK: - Weekly Report Response
struct WeeklyReportResponse: Content {
    let weekStart: String
    let weekEnd: String
    let avgCalories: Double
    let avgProtein: Double
    let avgSteps: Int?
    let daysGoalMet: Int
    let nutritionScore: Int
    let highlights: [String]

    enum CodingKeys: String, CodingKey {
        case avgCalories = "avg_calories"
        case avgProtein = "avg_protein"
        case avgSteps = "avg_steps"
        case daysGoalMet = "days_goal_met"
        case nutritionScore = "nutrition_score"
        case weekStart = "week_start"
        case weekEnd = "week_end"
        case highlights
    }
}
