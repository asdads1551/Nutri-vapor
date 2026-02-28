import Fluent
import Vapor

final class DailyNutritionSummary: Model, Content, @unchecked Sendable {
    static let schema = "daily_nutrition_summary"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "date") var date: Date
    @Field(key: "total_calories") var totalCalories: Double
    @Field(key: "total_protein") var totalProtein: Double
    @Field(key: "total_carbs") var totalCarbs: Double
    @Field(key: "total_fat") var totalFat: Double
    @Field(key: "total_fiber") var totalFiber: Double
    @Field(key: "total_sugar") var totalSugar: Double
    @Field(key: "total_sodium") var totalSodium: Double
    @Field(key: "total_water_ml") var totalWaterMl: Int
    @Field(key: "entry_count") var entryCount: Int
    @Field(key: "goal_met") var goalMet: Bool
    @Field(key: "score") var score: Int

    // Micronutrient totals (frontend-aligned)
    @Field(key: "total_potassium") var totalPotassium: Double
    @Field(key: "total_calcium") var totalCalcium: Double
    @Field(key: "total_iron") var totalIron: Double
    @Field(key: "total_zinc") var totalZinc: Double
    @Field(key: "total_vitamin_c") var totalVitaminC: Double
    @Field(key: "total_vitamin_d") var totalVitaminD: Double

    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}
}
