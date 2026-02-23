import Vapor
import Fluent

struct NutritionController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let nutrition = routes.grouped("nutrition")
        nutrition.post("entries", use: createEntry)
        nutrition.get("entries", use: listEntries)
        nutrition.get("entries", ":entryID", use: getEntry)
        nutrition.patch("entries", ":entryID", use: updateEntry)
        nutrition.delete("entries", ":entryID", use: deleteEntry)
        nutrition.get("summary", "daily", use: dailySummary)
        nutrition.get("summary", "weekly", use: weeklySummary)
        nutrition.get("summary", "monthly", use: monthlySummary)
        nutrition.get("trends", use: trends)
        nutrition.post("sync", use: sync)
    }

    // MARK: - POST /nutrition/entries
    @Sendable
    func createEntry(req: Request) async throws -> FoodEntryResponse {
        let userID = try req.authenticatedUserID
        let body = try req.content.decode(CreateFoodEntryRequest.self)

        guard let mealType = MealTypeDB(rawValue: body.mealType) ?? MealTypeDB(chinese: body.mealType) else {
            throw Abort(.badRequest, reason: "Invalid meal_type. Use: breakfast, lunch, dinner, snack")
        }

        let entry = FoodEntry(
            userID: userID,
            mealType: mealType,
            foodName: body.foodName,
            calories: body.calories,
            proteinG: body.proteinG ?? 0,
            carbsG: body.carbsG ?? 0,
            fatG: body.fatG ?? 0,
            fiberG: body.fiberG ?? 0,
            sugarG: body.sugarG ?? 0,
            sodiumMg: body.sodiumMg ?? 0,
            potassiumMg: body.potassiumMg ?? 0,
            calciumMg: body.calciumMg ?? 0,
            ironMg: body.ironMg ?? 0,
            zincMg: body.zincMg ?? 0,
            vitaminCMg: body.vitaminCMg ?? 0,
            vitaminDMcg: body.vitaminDMcg ?? 0,
            eatenAt: body.eatenAt ?? Date()
        )

        try await entry.save(on: req.db)

        return FoodEntryResponse(
            id: entry.id!,
            mealType: entry.mealType.chinese,
            foodName: entry.foodName,
            calories: entry.calories,
            proteinG: entry.proteinG,
            carbsG: entry.carbsG,
            fatG: entry.fatG,
            fiberG: entry.fiberG,
            eatenAt: entry.eatenAt,
            dailySummary: nil
        )
    }

    // MARK: - GET /nutrition/entries
    @Sendable
    func listEntries(req: Request) async throws -> [FoodEntryResponse] {
        let userID = try req.authenticatedUserID
        var query = FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)

        // Filter by date
        if let dateStr = req.query[String.self, at: "date"] {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateStr) {
                let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
                query = query
                    .filter(\.$eatenAt >= date)
                    .filter(\.$eatenAt < nextDay)
            }
        }

        // Filter by meal type
        if let mealTypeStr = req.query[String.self, at: "meal_type"],
           let mealType = MealTypeDB(rawValue: mealTypeStr) {
            query = query.filter(\.$mealType == mealType)
        }

        let entries = try await query
            .sort(\.$eatenAt, .ascending)
            .all()

        return entries.map { entry in
            FoodEntryResponse(
                id: entry.id!,
                mealType: entry.mealType.chinese,
                foodName: entry.foodName,
                calories: entry.calories,
                proteinG: entry.proteinG,
                carbsG: entry.carbsG,
                fatG: entry.fatG,
                fiberG: entry.fiberG,
                eatenAt: entry.eatenAt,
                dailySummary: nil
            )
        }
    }

    // MARK: - GET /nutrition/entries/:entryID
    @Sendable
    func getEntry(req: Request) async throws -> FoodEntryResponse {
        let userID = try req.authenticatedUserID
        guard let entryID = req.parameters.get("entryID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid entry ID")
        }

        guard let entry = try await FoodEntry.query(on: req.db)
            .filter(\.$id == entryID)
            .filter(\.$user.$id == userID)
            .first() else {
            throw Abort(.notFound, reason: "Entry not found")
        }

        return FoodEntryResponse(
            id: entry.id!,
            mealType: entry.mealType.chinese,
            foodName: entry.foodName,
            calories: entry.calories,
            proteinG: entry.proteinG,
            carbsG: entry.carbsG,
            fatG: entry.fatG,
            fiberG: entry.fiberG,
            eatenAt: entry.eatenAt,
            dailySummary: nil
        )
    }

    // MARK: - PATCH /nutrition/entries/:entryID
    @Sendable
    func updateEntry(req: Request) async throws -> FoodEntryResponse {
        let userID = try req.authenticatedUserID
        guard let entryID = req.parameters.get("entryID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid entry ID")
        }
        let body = try req.content.decode(UpdateFoodEntryRequest.self)

        guard let entry = try await FoodEntry.query(on: req.db)
            .filter(\.$id == entryID)
            .filter(\.$user.$id == userID)
            .first() else {
            throw Abort(.notFound, reason: "Entry not found")
        }

        if let mealTypeStr = body.mealType,
           let mealType = MealTypeDB(rawValue: mealTypeStr) ?? MealTypeDB(chinese: mealTypeStr) {
            entry.mealType = mealType
        }
        if let foodName = body.foodName { entry.foodName = foodName }
        if let calories = body.calories { entry.calories = calories }
        if let proteinG = body.proteinG { entry.proteinG = proteinG }
        if let carbsG = body.carbsG { entry.carbsG = carbsG }
        if let fatG = body.fatG { entry.fatG = fatG }
        if let fiberG = body.fiberG { entry.fiberG = fiberG }

        try await entry.save(on: req.db)

        return FoodEntryResponse(
            id: entry.id!,
            mealType: entry.mealType.chinese,
            foodName: entry.foodName,
            calories: entry.calories,
            proteinG: entry.proteinG,
            carbsG: entry.carbsG,
            fatG: entry.fatG,
            fiberG: entry.fiberG,
            eatenAt: entry.eatenAt,
            dailySummary: nil
        )
    }

    // MARK: - DELETE /nutrition/entries/:entryID
    @Sendable
    func deleteEntry(req: Request) async throws -> SuccessResponse {
        let userID = try req.authenticatedUserID
        guard let entryID = req.parameters.get("entryID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid entry ID")
        }

        guard let entry = try await FoodEntry.query(on: req.db)
            .filter(\.$id == entryID)
            .filter(\.$user.$id == userID)
            .first() else {
            throw Abort(.notFound, reason: "Entry not found")
        }

        try await entry.delete(on: req.db)
        return SuccessResponse(message: "Entry deleted")
    }

    // MARK: - GET /nutrition/summary/daily
    @Sendable
    func dailySummary(req: Request) async throws -> DailySummaryResponse {
        let userID = try req.authenticatedUserID
        let dateStr = req.query[String.self, at: "date"] ?? {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use yyyy-MM-dd")
        }

        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= date)
            .filter(\.$eatenAt < nextDay)
            .all()

        let totalCalories = entries.reduce(0.0) { $0 + $1.calories }
        let totalProtein = entries.reduce(0.0) { $0 + $1.proteinG }
        let totalCarbs = entries.reduce(0.0) { $0 + $1.carbsG }
        let totalFat = entries.reduce(0.0) { $0 + $1.fatG }
        let totalFiber = entries.reduce(0.0) { $0 + $1.fiberG }

        // Get user's calorie goal
        let goals = try await NutritionGoal.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()
        let calorieGoal = Double(goals?.calories ?? 2000)
        let goalMet = totalCalories >= calorieGoal * 0.8 && totalCalories <= calorieGoal * 1.2
        let score = min(100, Int((totalCalories / calorieGoal) * 100))

        return DailySummaryResponse(
            date: dateStr,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            totalFiber: totalFiber,
            entryCount: entries.count,
            goalMet: goalMet,
            score: score
        )
    }

    // MARK: - GET /nutrition/summary/weekly
    @Sendable
    func weeklySummary(req: Request) async throws -> [DailySummaryResponse] {
        let userID = try req.authenticatedUserID
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= weekAgo)
            .filter(\.$eatenAt < calendar.date(byAdding: .day, value: 1, to: today)!)
            .all()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Group by day
        var dailyMap: [String: [FoodEntry]] = [:]
        for entry in entries {
            let key = formatter.string(from: entry.eatenAt)
            dailyMap[key, default: []].append(entry)
        }

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let key = formatter.string(from: date)
            let dayEntries = dailyMap[key] ?? []

            return DailySummaryResponse(
                date: key,
                totalCalories: dayEntries.reduce(0) { $0 + $1.calories },
                totalProtein: dayEntries.reduce(0) { $0 + $1.proteinG },
                totalCarbs: dayEntries.reduce(0) { $0 + $1.carbsG },
                totalFat: dayEntries.reduce(0) { $0 + $1.fatG },
                totalFiber: dayEntries.reduce(0) { $0 + $1.fiberG },
                entryCount: dayEntries.count,
                goalMet: false,
                score: 0
            )
        }.reversed()
    }

    // MARK: - GET /nutrition/summary/monthly
    @Sendable
    func monthlySummary(req: Request) async throws -> [DailySummaryResponse] {
        let userID = try req.authenticatedUserID
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: today)!

        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= monthAgo)
            .all()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var dailyMap: [String: [FoodEntry]] = [:]
        for entry in entries {
            let key = formatter.string(from: entry.eatenAt)
            dailyMap[key, default: []].append(entry)
        }

        return dailyMap.map { (key, dayEntries) in
            DailySummaryResponse(
                date: key,
                totalCalories: dayEntries.reduce(0) { $0 + $1.calories },
                totalProtein: dayEntries.reduce(0) { $0 + $1.proteinG },
                totalCarbs: dayEntries.reduce(0) { $0 + $1.carbsG },
                totalFat: dayEntries.reduce(0) { $0 + $1.fatG },
                totalFiber: dayEntries.reduce(0) { $0 + $1.fiberG },
                entryCount: dayEntries.count,
                goalMet: false,
                score: 0
            )
        }.sorted { $0.date < $1.date }
    }

    // MARK: - GET /nutrition/trends
    @Sendable
    func trends(req: Request) async throws -> TrendResponse {
        let userID = try req.authenticatedUserID
        let metric = req.query[String.self, at: "metric"] ?? "calories"
        let range = req.query[String.self, at: "range"] ?? "30d"

        let days = Int(range.replacingOccurrences(of: "d", with: "")) ?? 30
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!

        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= startDate)
            .all()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var dailyMap: [String: Double] = [:]
        for entry in entries {
            let key = formatter.string(from: entry.eatenAt)
            let value: Double
            switch metric {
            case "protein": value = entry.proteinG
            case "carbs": value = entry.carbsG
            case "fat": value = entry.fatG
            case "fiber": value = entry.fiberG
            default: value = entry.calories
            }
            dailyMap[key, default: 0] += value
        }

        let data = dailyMap.map { TrendDataPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }

        let average = data.isEmpty ? 0 : data.reduce(0) { $0 + $1.value } / Double(data.count)

        let goals = try await NutritionGoal.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()
        let goal: Double
        switch metric {
        case "protein": goal = goals?.proteinG ?? 60
        case "carbs": goal = goals?.carbsG ?? 250
        case "fat": goal = goals?.fatG ?? 65
        case "fiber": goal = goals?.fiberG ?? 25
        default: goal = Double(goals?.calories ?? 2000)
        }

        let daysGoalMet = data.filter { $0.value >= goal * 0.8 }.count

        return TrendResponse(
            metric: metric,
            range: range,
            data: data,
            average: average,
            goal: goal,
            daysGoalMet: daysGoalMet
        )
    }

    // MARK: - POST /nutrition/sync
    @Sendable
    func sync(req: Request) async throws -> NutritionSyncResponse {
        let userID = try req.authenticatedUserID
        let body = try req.content.decode(NutritionSyncRequest.self)

        var synced: [FoodEntryResponse] = []

        for entryReq in body.entries {
            guard let mealType = MealTypeDB(rawValue: entryReq.mealType) ?? MealTypeDB(chinese: entryReq.mealType) else {
                continue
            }

            let entry = FoodEntry(
                userID: userID,
                mealType: mealType,
                foodName: entryReq.foodName,
                calories: entryReq.calories,
                proteinG: entryReq.proteinG ?? 0,
                carbsG: entryReq.carbsG ?? 0,
                fatG: entryReq.fatG ?? 0,
                fiberG: entryReq.fiberG ?? 0,
                eatenAt: entryReq.eatenAt ?? Date()
            )
            try await entry.save(on: req.db)

            synced.append(FoodEntryResponse(
                id: entry.id!,
                mealType: entry.mealType.chinese,
                foodName: entry.foodName,
                calories: entry.calories,
                proteinG: entry.proteinG,
                carbsG: entry.carbsG,
                fatG: entry.fatG,
                fiberG: entry.fiberG,
                eatenAt: entry.eatenAt,
                dailySummary: nil
            ))
        }

        return NutritionSyncResponse(synced: synced, serverUpdates: [])
    }
}
