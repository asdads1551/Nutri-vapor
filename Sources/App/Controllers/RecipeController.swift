import Vapor
import Fluent

struct RecipeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let recipes = routes.grouped("recipes")
        recipes.get(use: listRecipes)
        recipes.get(":recipeID", use: getRecipe)
        recipes.get("popular", use: popularRecipes)
        recipes.get("recommended", use: recommendedRecipes)
        recipes.post("favorites", ":recipeID", use: addFavorite)
        recipes.delete("favorites", ":recipeID", use: removeFavorite)
        recipes.get("favorites", use: listFavorites)
    }

    // MARK: - GET /recipes
    @Sendable
    func listRecipes(req: Request) async throws -> PagedResponse<RecipeListItem> {
        let userID = try req.authenticatedUserID
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = min(req.query[Int.self, at: "limit"] ?? APIConstants.defaultPageSize, APIConstants.maxPageSize)

        var query = Recipe.query(on: req.db)
            .filter(\.$isPublished == true)

        // Search
        if let search = req.query[String.self, at: "search"] {
            query = query.filter(\.$name ~~ search)
        }

        // Cuisine type filter
        if let cuisineStr = req.query[String.self, at: "cuisine_type"],
           let cuisine = CuisineTypeDB(rawValue: cuisineStr) ?? CuisineTypeDB(chinese: cuisineStr) {
            query = query.filter(\.$cuisineType == cuisine)
        }

        // Max calories
        if let maxCalories = req.query[Int.self, at: "max_calories"] {
            query = query.filter(\.$calories <= maxCalories)
        }

        // Max cooking time
        if let maxTime = req.query[Int.self, at: "max_cooking_time"] {
            query = query.filter(\.$cookingTimeMin <= maxTime)
        }

        let total = try await query.count()
        let recipes = try await query
            .with(\.$tags)
            .range(lower: (page - 1) * limit, upper: page * limit)
            .all()

        // Get user's favorites
        let favoriteRecipeIDs = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()
            .map { $0.$recipe.id }

        let items = recipes.map { recipe in
            RecipeListItem(
                id: recipe.id!,
                name: recipe.name,
                calories: recipe.calories,
                cookingTimeMin: recipe.cookingTimeMin,
                servings: recipe.servings,
                priceNtd: recipe.priceNtd,
                tags: recipe.tags.map { $0.tag.chinese },
                cuisineType: recipe.cuisineType?.chinese,
                imageURL: recipe.imageURL,
                isFavorite: favoriteRecipeIDs.contains(recipe.id!)
            )
        }

        return PagedResponse(
            data: items,
            page: page,
            perPage: limit,
            total: total,
            totalPages: max(1, (total + limit - 1) / limit)
        )
    }

    // MARK: - GET /recipes/:recipeID
    @Sendable
    func getRecipe(req: Request) async throws -> RecipeDetailResponse {
        let userID = try req.authenticatedUserID
        guard let recipeID = req.parameters.get("recipeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let recipe = try await Recipe.query(on: req.db)
            .filter(\.$id == recipeID)
            .with(\.$tags)
            .with(\.$ingredients)
            .first() else {
            throw Abort(.notFound, reason: "Recipe not found")
        }

        let isFavorite = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$recipe.$id == recipeID)
            .count() > 0

        return RecipeDetailResponse(
            id: recipe.id!,
            name: recipe.name,
            description: recipe.description,
            calories: recipe.calories,
            cookingTimeMin: recipe.cookingTimeMin,
            difficulty: recipe.difficulty.rawValue,
            servings: recipe.servings,
            priceNtd: recipe.priceNtd,
            nutrition: NutritionInfoResponse(
                proteinG: recipe.proteinG,
                carbsG: recipe.carbsG,
                fatG: recipe.fatG,
                fiberG: recipe.fiberG
            ),
            ingredients: recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder }).map {
                IngredientResponse(name: $0.name, amount: $0.amount, unit: $0.unit)
            },
            tags: recipe.tags.map { $0.tag.chinese },
            cuisineType: recipe.cuisineType?.chinese,
            steps: recipe.steps,
            imageURL: recipe.imageURL,
            isFavorite: isFavorite
        )
    }

    // MARK: - GET /recipes/popular
    @Sendable
    func popularRecipes(req: Request) async throws -> [RecipeListItem] {
        let userID = try req.authenticatedUserID

        // Get recipes sorted by favorite count (simplified)
        let recipes = try await Recipe.query(on: req.db)
            .filter(\.$isPublished == true)
            .with(\.$tags)
            .limit(20)
            .all()

        let favoriteRecipeIDs = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()
            .map { $0.$recipe.id }

        return recipes.map { recipe in
            RecipeListItem(
                id: recipe.id!,
                name: recipe.name,
                calories: recipe.calories,
                cookingTimeMin: recipe.cookingTimeMin,
                servings: recipe.servings,
                priceNtd: recipe.priceNtd,
                tags: recipe.tags.map { $0.tag.chinese },
                cuisineType: recipe.cuisineType?.chinese,
                imageURL: recipe.imageURL,
                isFavorite: favoriteRecipeIDs.contains(recipe.id!)
            )
        }
    }

    // MARK: - GET /recipes/recommended
    @Sendable
    func recommendedRecipes(req: Request) async throws -> RecommendedRecipeResponse {
        let userID = try req.authenticatedUserID

        // Get today's nutrition
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todayEntries = try await FoodEntry.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$eatenAt >= today)
            .filter(\.$eatenAt < tomorrow)
            .all()

        let goals = try await NutritionGoal.query(on: req.db)
            .filter(\.$user.$id == userID)
            .first()

        let totalProtein = todayEntries.reduce(0.0) { $0 + $1.proteinG }
        let totalFiber = todayEntries.reduce(0.0) { $0 + $1.fiberG }
        let totalCalories = todayEntries.reduce(0.0) { $0 + $1.calories }

        let proteinGap = (goals?.proteinG ?? 60) - totalProtein
        let fiberGap = (goals?.fiberG ?? 25) - totalFiber
        let caloriesRemaining = Double(goals?.calories ?? 2000) - totalCalories

        // Find recipes that fill the gaps
        let recipes = try await Recipe.query(on: req.db)
            .filter(\.$isPublished == true)
            .with(\.$tags)
            .limit(10)
            .all()

        let items: [RecommendedRecipeItem] = recipes.compactMap { recipe in
            var reason: String?
            if proteinGap > 10 && recipe.proteinG > 15 {
                reason = "高蛋白 — 補充今日蛋白質缺口"
            } else if fiberGap > 5 && recipe.fiberG > 5 {
                reason = "高纖維 — 補充今日纖維攝取"
            } else if caloriesRemaining > 300 && recipe.calories <= Int(caloriesRemaining) {
                reason = "熱量適中 — 符合今日剩餘額度"
            }

            guard let matchReason = reason else { return nil }

            let favoriteIDs: [UUID] = [] // Simplified

            return RecommendedRecipeItem(
                recipe: RecipeListItem(
                    id: recipe.id!,
                    name: recipe.name,
                    calories: recipe.calories,
                    cookingTimeMin: recipe.cookingTimeMin,
                    servings: recipe.servings,
                    priceNtd: recipe.priceNtd,
                    tags: recipe.tags.map { $0.tag.chinese },
                    cuisineType: recipe.cuisineType?.chinese,
                    imageURL: recipe.imageURL,
                    isFavorite: favoriteIDs.contains(recipe.id!)
                ),
                matchReason: matchReason
            )
        }

        return RecommendedRecipeResponse(
            gaps: NutritionGaps(
                proteinG: max(0, proteinGap),
                fiberG: max(0, fiberGap),
                caloriesRemaining: max(0, caloriesRemaining)
            ),
            recipes: items
        )
    }

    // MARK: - POST /recipes/favorites/:recipeID
    @Sendable
    func addFavorite(req: Request) async throws -> SuccessResponse {
        let userID = try req.authenticatedUserID
        guard let recipeID = req.parameters.get("recipeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        // Check if already favorited
        let existing = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$recipe.$id == recipeID)
            .first()

        guard existing == nil else {
            return SuccessResponse(message: "Already in favorites")
        }

        let favorite = UserFavorite(userID: userID, recipeID: recipeID)
        try await favorite.save(on: req.db)
        return SuccessResponse(message: "Added to favorites")
    }

    // MARK: - DELETE /recipes/favorites/:recipeID
    @Sendable
    func removeFavorite(req: Request) async throws -> SuccessResponse {
        let userID = try req.authenticatedUserID
        guard let recipeID = req.parameters.get("recipeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$recipe.$id == recipeID)
            .delete()

        return SuccessResponse(message: "Removed from favorites")
    }

    // MARK: - GET /recipes/favorites
    @Sendable
    func listFavorites(req: Request) async throws -> [RecipeListItem] {
        let userID = try req.authenticatedUserID

        let favorites = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .with(\.$recipe) {
                $0.with(\.$tags)
            }
            .all()

        return favorites.map { fav in
            let recipe = fav.recipe
            return RecipeListItem(
                id: recipe.id!,
                name: recipe.name,
                calories: recipe.calories,
                cookingTimeMin: recipe.cookingTimeMin,
                servings: recipe.servings,
                priceNtd: recipe.priceNtd,
                tags: recipe.tags.map { $0.tag.chinese },
                cuisineType: recipe.cuisineType?.chinese,
                imageURL: recipe.imageURL,
                isFavorite: true
            )
        }
    }
}
