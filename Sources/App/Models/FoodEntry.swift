import Fluent
import Vapor

/// Corresponds to iOS `FoodEntry` in NutritionTracker.swift
final class FoodEntry: Model, Content, @unchecked Sendable {
    static let schema = "food_entries"

    @ID(key: .id) var id: UUID?
    @Parent(key: "user_id") var user: User
    @Field(key: "meal_type") var mealType: MealTypeDB
    @Field(key: "food_name") var foodName: String
    @Field(key: "portion_size") var portionSize: Double?
    @Field(key: "portion_unit") var portionUnit: String?
    @Field(key: "image_url") var imageURL: String?
    @Field(key: "source") var source: FoodSource

    // Macronutrients (巨量營養素)
    @Field(key: "calories") var calories: Double
    @Field(key: "protein_g") var proteinG: Double
    @Field(key: "carbs_g") var carbsG: Double
    @Field(key: "fat_g") var fatG: Double
    @Field(key: "fiber_g") var fiberG: Double
    @Field(key: "sugar_g") var sugarG: Double

    // Micronutrients (微量營養素)
    @Field(key: "sodium_mg") var sodiumMg: Double
    @Field(key: "potassium_mg") var potassiumMg: Double
    @Field(key: "calcium_mg") var calciumMg: Double
    @Field(key: "iron_mg") var ironMg: Double
    @Field(key: "zinc_mg") var zincMg: Double
    @Field(key: "vitamin_c_mg") var vitaminCMg: Double
    @Field(key: "vitamin_d_mcg") var vitaminDMcg: Double

    // Timestamps
    @Field(key: "eaten_at") var eatenAt: Date
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        mealType: MealTypeDB,
        foodName: String,
        calories: Double,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0,
        fiberG: Double = 0,
        sugarG: Double = 0,
        sodiumMg: Double = 0,
        potassiumMg: Double = 0,
        calciumMg: Double = 0,
        ironMg: Double = 0,
        zincMg: Double = 0,
        vitaminCMg: Double = 0,
        vitaminDMcg: Double = 0,
        eatenAt: Date = Date(),
        source: FoodSource = .manual
    ) {
        self.id = id
        self.$user.id = userID
        self.mealType = mealType
        self.foodName = foodName
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
        self.sugarG = sugarG
        self.sodiumMg = sodiumMg
        self.potassiumMg = potassiumMg
        self.calciumMg = calciumMg
        self.ironMg = ironMg
        self.zincMg = zincMg
        self.vitaminCMg = vitaminCMg
        self.vitaminDMcg = vitaminDMcg
        self.eatenAt = eatenAt
        self.source = source
    }
}
