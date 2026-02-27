import Vapor
import Fluent

/// Business logic for recipe-related operations
struct RecipeService {
    let db: Database

    /// Get recipe recommendations based on user's nutrition gaps
    func getRecommendations(userID: UUID, limit: Int = 5) async throws -> [(Recipe, String)] {
        let calendar = Calendar.taipei
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Get today's entries
        let entries = try await FoodEntry.query(on: db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= today)
            .filter(\.$eatenAt < tomorrow)
            .all()

        let goals = try await NutritionGoal.query(on: db)
            .filter(\.$user.$id == userID)
            .first()

        let totalProtein = entries.reduce(0.0) { $0 + $1.proteinG }
        let totalFiber = entries.reduce(0.0) { $0 + $1.fiberG }
        let totalCalories = entries.reduce(0.0) { $0 + $1.calories }

        let proteinGap = (goals?.proteinG ?? 60) - totalProtein
        let fiberGap = (goals?.fiberG ?? 25) - totalFiber
        let caloriesRemaining = Double(goals?.calories ?? 2000) - totalCalories

        // Find matching recipes
        let recipes = try await Recipe.query(on: db)
            .filter(\.$isPublished == true)
            .with(\.$tags)
            .limit(limit * 3) // fetch more, then filter
            .all()

        var results: [(Recipe, String)] = []

        for recipe in recipes {
            if proteinGap > 10 && recipe.proteinG > 15 {
                results.append((recipe, "高蛋白 — 補充今日蛋白質缺口"))
            } else if fiberGap > 5 && recipe.fiberG > 5 {
                results.append((recipe, "高纖維 — 補充今日纖維攝取"))
            } else if caloriesRemaining > 300 && recipe.calories <= Int(caloriesRemaining) {
                results.append((recipe, "熱量適中 — 符合今日剩餘額度"))
            }

            if results.count >= limit { break }
        }

        return results
    }

    /// Search recipes by keyword
    func search(keyword: String, limit: Int = 20) async throws -> [Recipe] {
        try await Recipe.query(on: db)
            .filter(\.$isPublished == true)
            .filter(\.$name ~~ keyword)
            .with(\.$tags)
            .with(\.$ingredients)
            .limit(limit)
            .all()
    }
}
