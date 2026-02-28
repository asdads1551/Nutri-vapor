import Vapor
import Fluent

/// Business logic for nutrition-related operations
struct NutritionService {
    let db: Database

    /// Calculate and update daily nutrition summary for a user on a given date
    func updateDailySummary(userID: UUID, date: Date) async throws {
        let calendar = Calendar.taipei
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let entries = try await FoodEntry.query(on: db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= startOfDay)
            .filter(\.$eatenAt < endOfDay)
            .all()

        let totalCalories = entries.reduce(0.0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0.0) { $0 + $1.proteinG }
        let totalCarbs = entries.reduce(0.0) { $0 + $1.carbsG }
        let totalFat = entries.reduce(0.0) { $0 + $1.fatG }
        let totalFiber = entries.reduce(0.0) { $0 + $1.fiberG }
        let totalSugar = entries.reduce(0.0) { $0 + $1.sugarG }
        let totalSodium = entries.reduce(0.0) { $0 + $1.sodiumMg }

        // Micronutrient totals
        let totalPotassium = entries.reduce(0.0) { $0 + $1.potassiumMg }
        let totalCalcium = entries.reduce(0.0) { $0 + $1.calciumMg }
        let totalIron = entries.reduce(0.0) { $0 + $1.ironMg }
        let totalZinc = entries.reduce(0.0) { $0 + $1.zincMg }
        let totalVitaminC = entries.reduce(0.0) { $0 + $1.vitaminCMg }
        let totalVitaminD = entries.reduce(0.0) { $0 + $1.vitaminDMcg }

        // Get user goals
        let goals = try await NutritionGoal.query(on: db)
            .filter(\.$user.$id == userID)
            .first()

        let calorieGoal = Double(goals?.calories ?? 2000)
        let goalMet = totalCalories >= calorieGoal * 0.8 && totalCalories <= calorieGoal * 1.2

        // Calculate nutrition score (0-100)
        let calorieScore = min(1.0, totalCalories / calorieGoal)
        let proteinScore = min(1.0, totalProtein / (goals?.proteinG ?? 60))
        let fiberScore = min(1.0, totalFiber / (goals?.fiberG ?? 25))
        let score = Int((calorieScore * 0.4 + proteinScore * 0.3 + fiberScore * 0.3) * 100)

        // Upsert daily summary
        if let existing = try await DailyNutritionSummary.query(on: db)
            .filter(\.$user.$id == userID)
            .filter(\.$date == startOfDay)
            .first() {
            existing.totalCalories = totalCalories
            existing.totalProtein = totalProtein
            existing.totalCarbs = totalCarbs
            existing.totalFat = totalFat
            existing.totalFiber = totalFiber
            existing.totalSugar = totalSugar
            existing.totalSodium = totalSodium
            existing.totalPotassium = totalPotassium
            existing.totalCalcium = totalCalcium
            existing.totalIron = totalIron
            existing.totalZinc = totalZinc
            existing.totalVitaminC = totalVitaminC
            existing.totalVitaminD = totalVitaminD
            existing.entryCount = entries.count
            existing.goalMet = goalMet
            existing.score = score
            try await existing.save(on: db)
        } else {
            let summary = DailyNutritionSummary()
            summary.$user.id = userID
            summary.date = startOfDay
            summary.totalCalories = totalCalories
            summary.totalProtein = totalProtein
            summary.totalCarbs = totalCarbs
            summary.totalFat = totalFat
            summary.totalFiber = totalFiber
            summary.totalSugar = totalSugar
            summary.totalSodium = totalSodium
            summary.totalPotassium = totalPotassium
            summary.totalCalcium = totalCalcium
            summary.totalIron = totalIron
            summary.totalZinc = totalZinc
            summary.totalVitaminC = totalVitaminC
            summary.totalVitaminD = totalVitaminD
            summary.totalWaterMl = 0
            summary.entryCount = entries.count
            summary.goalMet = goalMet
            summary.score = score
            try await summary.save(on: db)
        }
    }
}
