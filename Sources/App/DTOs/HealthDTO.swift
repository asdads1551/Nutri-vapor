import Vapor

// MARK: - Health Sync Request (frontend-aligned)
struct HealthSyncRequest: Content, Validatable {
    let date: String
    let steps: Int?
    let stepsChange: Double?
    let activeCalories: Double?
    let weight: Double?
    let weightChange: Double?
    let heartRate: Int?
    let sleepHours: Double?

    enum CodingKeys: String, CodingKey {
        case date, steps, weight
        case stepsChange = "steps_change"
        case activeCalories = "active_calories"
        case weightChange = "weight_change"
        case heartRate = "heart_rate"
        case sleepHours = "sleep_hours"
    }

    static func validations(_ validations: inout Validations) {
        validations.add("date", as: String.self, is: .count(10...10))
        validations.add("steps", as: Int?.self, is: .nil || .range(0...500000), required: false)
        validations.add("active_calories", as: Double?.self, is: .nil || .range(0...50000), required: false)
        validations.add("weight", as: Double?.self, is: .nil || .range(10...500), required: false)
        validations.add("heart_rate", as: Int?.self, is: .nil || .range(20...300), required: false)
        validations.add("sleep_hours", as: Double?.self, is: .nil || .range(0...24), required: false)
    }
}

// MARK: - Health Summary Response (frontend-aligned)
// Frontend expects steps/activeCalories as non-optional Int, stepsChange as non-optional Double
struct HealthSummaryResponse: Content {
    let date: String
    let steps: Int
    let stepsChange: Double
    let activeCalories: Int
    let weight: Double?
    let heartRate: Int?
    let sleepHours: Double?

    enum CodingKeys: String, CodingKey {
        case date, steps, weight
        case stepsChange = "steps_change"
        case activeCalories = "active_calories"
        case heartRate = "heart_rate"
        case sleepHours = "sleep_hours"
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
