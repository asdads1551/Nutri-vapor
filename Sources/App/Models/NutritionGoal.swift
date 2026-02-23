import Fluent
import Vapor

final class NutritionGoal: Model, Content, @unchecked Sendable {
    static let schema = "nutrition_goals"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "calories") var calories: Int
    @Field(key: "protein_g") var proteinG: Double
    @Field(key: "carbs_g") var carbsG: Double
    @Field(key: "fat_g") var fatG: Double
    @Field(key: "fiber_g") var fiberG: Double
    @Field(key: "sugar_g") var sugarG: Double
    @Field(key: "sodium_mg") var sodiumMg: Double
    @Field(key: "water_ml") var waterMl: Int
    @Field(key: "effective_date") var effectiveDate: Date
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        calories: Int = 2000,
        proteinG: Double = 60,
        carbsG: Double = 250,
        fatG: Double = 65,
        fiberG: Double = 25,
        sugarG: Double = 50,
        sodiumMg: Double = 2300,
        waterMl: Int = 2000,
        effectiveDate: Date = Date()
    ) {
        self.id = id
        self.$user.id = userID
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.sugarG = sugarG
        self.sodiumMg = sodiumMg
        self.waterMl = waterMl
        self.effectiveDate = effectiveDate
    }
}
