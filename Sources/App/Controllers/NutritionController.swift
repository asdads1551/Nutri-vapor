import Vapor
import Fluent

/// Thread-safe counter for use inside Sendable closures (e.g. db.transaction)
private final class SyncCounter: @unchecked Sendable {
    var value: Int = 0
}

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

    // MARK: - Helper: Build FoodEntryResponse from Model

    private func buildEntryResponse(_ entry: FoodEntry) -> FoodEntryResponse {
        FoodEntryResponse(
            id: entry.id!.uuidString,
            name: entry.foodName,
            calories: entry.calories,
            carbs: entry.carbsG,
            protein: entry.proteinG,
            fat: entry.fatG,
            fiber: entry.fiberG,
            sugar: entry.sugarG,
            sodium: entry.sodiumMg,
            potassium: entry.potassiumMg,
            calcium: entry.calciumMg,
            iron: entry.ironMg,
            zinc: entry.zincMg,
            vitaminC: entry.vitaminCMg,
            vitaminD: entry.vitaminDMcg,
            mealType: entry.mealType.rawValue,
            imageUrl: entry.imageURL,
            timestamp: entry.eatenAt
        )
    }

    // MARK: - Helper: Build DailySummaryResponse from entries

    private func buildDailySummary(date: String?, entries: [FoodEntry]) -> DailySummaryResponse {
        DailySummaryResponse(
            date: date,
            totalCalories: entries.reduce(0.0) { $0 + $1.calories },
            totalCarbs: entries.reduce(0.0) { $0 + $1.carbsG },
            totalProtein: entries.reduce(0.0) { $0 + $1.proteinG },
            totalFat: entries.reduce(0.0) { $0 + $1.fatG },
            totalFiber: entries.reduce(0.0) { $0 + $1.fiberG },
            totalSugar: entries.reduce(0.0) { $0 + $1.sugarG },
            totalSodium: entries.reduce(0.0) { $0 + $1.sodiumMg },
            totalPotassium: entries.reduce(0.0) { $0 + $1.potassiumMg },
            totalCalcium: entries.reduce(0.0) { $0 + $1.calciumMg },
            totalIron: entries.reduce(0.0) { $0 + $1.ironMg },
            totalZinc: entries.reduce(0.0) { $0 + $1.zincMg },
            totalVitaminC: entries.reduce(0.0) { $0 + $1.vitaminCMg },
            totalVitaminD: entries.reduce(0.0) { $0 + $1.vitaminDMcg },
            entryCount: entries.count
        )
    }

    // MARK: - POST /nutrition/entries
    @Sendable
    func createEntry(req: Request) async throws -> FoodEntryResponse {
        let userID = try req.authenticatedUserID
        try CreateFoodEntryRequest.validate(content: req)
        let body = try req.content.decode(CreateFoodEntryRequest.self)

        guard let mealType = MealTypeDB(rawValue: body.mealType) ?? MealTypeDB(chinese: body.mealType) else {
            throw Abort(.badRequest, reason: "Invalid meal_type. Use: breakfast, lunch, dinner, snack")
        }

        let entry = FoodEntry(
            userID: userID,
            mealType: mealType,
            foodName: body.name,
            calories: body.calories,
            proteinG: body.protein ?? 0,
            carbsG: body.carbs ?? 0,
            fatG: body.fat ?? 0,
            fiberG: body.fiber ?? 0,
            sugarG: body.sugar ?? 0,
            sodiumMg: body.sodium ?? 0,
            potassiumMg: body.potassium ?? 0,
            calciumMg: body.calcium ?? 0,
            ironMg: body.iron ?? 0,
            zincMg: body.zinc ?? 0,
            vitaminCMg: body.vitaminC ?? 0,
            vitaminDMcg: body.vitaminD ?? 0,
            eatenAt: body.timestamp ?? Date()
        )
        entry.imageURL = body.imageUrl

        try await entry.save(on: req.db)

        return buildEntryResponse(entry)
    }

    // MARK: - GET /nutrition/entries
    @Sendable
    func listEntries(req: Request) async throws -> [FoodEntryResponse] {
        let userID = try req.authenticatedUserID
        var query = FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)

        // Filter by date
        if let dateStr = req.query[String.self, at: "date"] {
            if let date = DateFormatter.yyyyMMdd.date(from: dateStr) {
                let nextDay = Calendar.taipei.date(byAdding: .day, value: 1, to: date)!
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

        return entries.map { buildEntryResponse($0) }
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

        return buildEntryResponse(entry)
    }

    // MARK: - PATCH /nutrition/entries/:entryID
    @Sendable
    func updateEntry(req: Request) async throws -> FoodEntryResponse {
        let userID = try req.authenticatedUserID
        guard let entryID = req.parameters.get("entryID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid entry ID")
        }
        try UpdateFoodEntryRequest.validate(content: req)
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
        if let name = body.name { entry.foodName = name }
        if let calories = body.calories { entry.calories = calories }
        if let protein = body.protein { entry.proteinG = protein }
        if let carbs = body.carbs { entry.carbsG = carbs }
        if let fat = body.fat { entry.fatG = fat }

        try await entry.save(on: req.db)

        return buildEntryResponse(entry)
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
        let dateStr = req.query[String.self, at: "date"]
            ?? DateFormatter.yyyyMMdd.string(from: Date())

        guard let date = DateFormatter.yyyyMMdd.date(from: dateStr) else {
            throw Abort(.badRequest, reason: "Invalid date format. Use yyyy-MM-dd")
        }

        let nextDay = Calendar.taipei.date(byAdding: .day, value: 1, to: date)!
        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= date)
            .filter(\.$eatenAt < nextDay)
            .all()

        return buildDailySummary(date: dateStr, entries: entries)
    }

    // MARK: - GET /nutrition/summary/weekly
    @Sendable
    func weeklySummary(req: Request) async throws -> [DailySummaryResponse] {
        let userID = try req.authenticatedUserID
        let calendar = Calendar.taipei
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= weekAgo)
            .filter(\.$eatenAt < calendar.date(byAdding: .day, value: 1, to: today)!)
            .all()

        var dailyMap: [String: [FoodEntry]] = [:]
        for entry in entries {
            let key = DateFormatter.yyyyMMdd.string(from: entry.eatenAt)
            dailyMap[key, default: []].append(entry)
        }

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let key = DateFormatter.yyyyMMdd.string(from: date)
            let dayEntries = dailyMap[key] ?? []
            return buildDailySummary(date: key, entries: dayEntries)
        }.reversed()
    }

    // MARK: - GET /nutrition/summary/monthly
    @Sendable
    func monthlySummary(req: Request) async throws -> [DailySummaryResponse] {
        let userID = try req.authenticatedUserID
        let calendar = Calendar.taipei
        let today = calendar.startOfDay(for: Date())
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: today)!

        // Use pre-aggregated DailyNutritionSummary when available
        let summaries = try await DailyNutritionSummary.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$date >= monthAgo)
            .sort(\.$date, .ascending)
            .all()

        if !summaries.isEmpty {
            return summaries.map { s in
                DailySummaryResponse(
                    date: DateFormatter.yyyyMMdd.string(from: s.date),
                    totalCalories: s.totalCalories,
                    totalCarbs: s.totalCarbs,
                    totalProtein: s.totalProtein,
                    totalFat: s.totalFat,
                    totalFiber: s.totalFiber,
                    totalSugar: s.totalSugar,
                    totalSodium: s.totalSodium,
                    totalPotassium: s.totalPotassium,
                    totalCalcium: s.totalCalcium,
                    totalIron: s.totalIron,
                    totalZinc: s.totalZinc,
                    totalVitaminC: s.totalVitaminC,
                    totalVitaminD: s.totalVitaminD,
                    entryCount: s.entryCount
                )
            }
        }

        // Fallback: aggregate from FoodEntry
        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= monthAgo)
            .all()

        var dailyMap: [String: [FoodEntry]] = [:]
        for entry in entries {
            let key = DateFormatter.yyyyMMdd.string(from: entry.eatenAt)
            dailyMap[key, default: []].append(entry)
        }

        return dailyMap.map { (key, dayEntries) in
            buildDailySummary(date: key, entries: dayEntries)
        }.sorted { ($0.date ?? "") < ($1.date ?? "") }
    }

    // MARK: - GET /nutrition/trends
    @Sendable
    func trends(req: Request) async throws -> TrendResponse {
        let userID = try req.authenticatedUserID
        let metric = req.query[String.self, at: "metric"] ?? "calories"
        let range = req.query[String.self, at: "range"] ?? "30d"

        let days = min(Int(range.replacingOccurrences(of: "d", with: "")) ?? 30, 365)
        let calendar = Calendar.taipei
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!

        let entries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= startDate)
            .all()

        var dailyMap: [String: Double] = [:]
        for entry in entries {
            let key = DateFormatter.yyyyMMdd.string(from: entry.eatenAt)
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
        try NutritionSyncRequest.validate(content: req)
        let body = try req.content.decode(NutritionSyncRequest.self)

        let counter = SyncCounter()

        try await req.db.transaction { db in
            for syncEntry in body.entries {
                switch syncEntry.action {
                case "create":
                    guard let data = syncEntry.data else { continue }
                    guard let mealType = MealTypeDB(rawValue: data.mealType) ?? MealTypeDB(chinese: data.mealType) else {
                        continue
                    }

                    let entry = FoodEntry(
                        userID: userID,
                        mealType: mealType,
                        foodName: data.name,
                        calories: data.calories,
                        proteinG: data.protein ?? 0,
                        carbsG: data.carbs ?? 0,
                        fatG: data.fat ?? 0,
                        fiberG: data.fiber ?? 0,
                        sugarG: data.sugar ?? 0,
                        sodiumMg: data.sodium ?? 0,
                        potassiumMg: data.potassium ?? 0,
                        calciumMg: data.calcium ?? 0,
                        ironMg: data.iron ?? 0,
                        zincMg: data.zinc ?? 0,
                        vitaminCMg: data.vitaminC ?? 0,
                        vitaminDMcg: data.vitaminD ?? 0,
                        eatenAt: data.timestamp ?? Date()
                    )
                    entry.imageURL = data.imageUrl
                    try await entry.save(on: db)
                    counter.value += 1

                case "update":
                    guard let idStr = syncEntry.id,
                          let entryID = UUID(uuidString: idStr) else { continue }
                    guard let existing = try await FoodEntry.query(on: db)
                        .filter(\.$id == entryID)
                        .filter(\.$user.$id == userID)
                        .first() else { continue }

                    if let data = syncEntry.data {
                        if let mealType = MealTypeDB(rawValue: data.mealType) ?? MealTypeDB(chinese: data.mealType) {
                            existing.mealType = mealType
                        }
                        existing.foodName = data.name
                        existing.calories = data.calories
                        existing.proteinG = data.protein ?? existing.proteinG
                        existing.carbsG = data.carbs ?? existing.carbsG
                        existing.fatG = data.fat ?? existing.fatG
                        existing.fiberG = data.fiber ?? existing.fiberG
                        existing.sugarG = data.sugar ?? existing.sugarG
                        existing.sodiumMg = data.sodium ?? existing.sodiumMg
                        existing.potassiumMg = data.potassium ?? existing.potassiumMg
                        existing.calciumMg = data.calcium ?? existing.calciumMg
                        existing.ironMg = data.iron ?? existing.ironMg
                        existing.zincMg = data.zinc ?? existing.zincMg
                        existing.vitaminCMg = data.vitaminC ?? existing.vitaminCMg
                        existing.vitaminDMcg = data.vitaminD ?? existing.vitaminDMcg
                        if let ts = data.timestamp { existing.eatenAt = ts }
                        if let imageUrl = data.imageUrl { existing.imageURL = imageUrl }
                    }
                    try await existing.save(on: db)
                    counter.value += 1

                case "delete":
                    guard let idStr = syncEntry.id,
                          let entryID = UUID(uuidString: idStr) else { continue }
                    guard let existing = try await FoodEntry.query(on: db)
                        .filter(\.$id == entryID)
                        .filter(\.$user.$id == userID)
                        .first() else { continue }
                    try await existing.delete(force: true, on: db)
                    counter.value += 1

                default:
                    req.logger.warning("Nutrition sync: unknown action '\(syncEntry.action)'")
                }
            }
        }

        return NutritionSyncResponse(synced: counter.value, conflicts: nil)
    }
}
