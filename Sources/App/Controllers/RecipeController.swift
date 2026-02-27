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

    // MARK: - GET /recipes (#11: fix N+1 — only query favorites for current page recipe IDs)
    @Sendable
    func listRecipes(req: Request) async throws -> Response {
        let userID = try req.authenticatedUserID
        let page = max(1, req.query[Int.self, at: "page"] ?? 1)
        let limit = min(req.query[Int.self, at: "limit"] ?? APIConstants.defaultPageSize, APIConstants.maxPageSize)

        var query = Recipe.query(on: req.db)
            .filter(\.$isPublished == true)

        if let search = req.query[String.self, at: "search"] {
            let trimmed = String(search.prefix(200))
            query = query.filter(\.$name ~~ trimmed)
        }

        if let cuisineStr = req.query[String.self, at: "cuisine_type"],
           let cuisine = CuisineTypeDB(rawValue: cuisineStr) ?? CuisineTypeDB(chinese: cuisineStr) {
            query = query.filter(\.$cuisineType == cuisine)
        }

        if let maxCalories = req.query[Int.self, at: "max_calories"] {
            query = query.filter(\.$calories <= maxCalories)
        }

        if let maxTime = req.query[Int.self, at: "max_cooking_time"] {
            query = query.filter(\.$cookingTimeMin <= maxTime)
        }

        let total = try await query.count()
        let recipes = try await query
            .with(\.$tags)
            .range(lower: (page - 1) * limit, upper: page * limit)
            .all()

        // Only query favorites for the recipe IDs on this page (fixes N+1)
        let recipeIDs = recipes.compactMap(\.id)
        let favoriteSet: Set<UUID>
        if recipeIDs.isEmpty {
            favoriteSet = []
        } else {
            let favorites = try await UserFavorite.query(on: req.db)
                .filter(\.$user.$id == userID)
                .filter(\.$recipe.$id ~~ recipeIDs)
                .all()
            favoriteSet = Set(favorites.map { $0.$recipe.id })
        }

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
                isFavorite: favoriteSet.contains(recipe.id!)
            )
        }

        let body = PagedResponse(
            data: items,
            page: page,
            perPage: limit,
            total: total,
            totalPages: max(1, (total + limit - 1) / limit)
        )

        // (#20) Cache-Control for recipe list — short cache since favorites change
        let response = try await body.encodeResponse(for: req)
        response.headers.replaceOrAdd(name: .cacheControl, value: "private, max-age=60")
        return response
    }

    // MARK: - GET /recipes/:recipeID
    @Sendable
    func getRecipe(req: Request) async throws -> Response {
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

        // Use first() instead of count() for efficiency (#11)
        let isFavorite = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$recipe.$id == recipeID)
            .first() != nil

        let body = RecipeDetailResponse(
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

        // (#20) Recipe detail changes infrequently — cache 5 minutes
        let response = try await body.encodeResponse(for: req)
        response.headers.replaceOrAdd(name: .cacheControl, value: "private, max-age=300")
        return response
    }

    // MARK: - GET /recipes/popular
    @Sendable
    func popularRecipes(req: Request) async throws -> Response {
        let userID = try req.authenticatedUserID

        let recipes = try await Recipe.query(on: req.db)
            .filter(\.$isPublished == true)
            .with(\.$tags)
            .limit(20)
            .all()

        // Only query favorites for these recipe IDs (#11)
        let recipeIDs = recipes.compactMap(\.id)
        let favoriteSet: Set<UUID>
        if recipeIDs.isEmpty {
            favoriteSet = []
        } else {
            let favorites = try await UserFavorite.query(on: req.db)
                .filter(\.$user.$id == userID)
                .filter(\.$recipe.$id ~~ recipeIDs)
                .all()
            favoriteSet = Set(favorites.map { $0.$recipe.id })
        }

        let body = recipes.map { recipe in
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
                isFavorite: favoriteSet.contains(recipe.id!)
            )
        }

        // (#20) Popular recipes — cache 5 minutes
        let response = try await body.encodeResponse(for: req)
        response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=300")
        return response
    }

    // MARK: - GET /recipes/recommended (#11: fix hardcoded empty favoriteIDs)
    @Sendable
    func recommendedRecipes(req: Request) async throws -> RecommendedRecipeResponse {
        let userID = try req.authenticatedUserID

        let calendar = Calendar.taipei
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

        let recipes = try await Recipe.query(on: req.db)
            .filter(\.$isPublished == true)
            .with(\.$tags)
            .limit(30)
            .all()

        // Query favorites for all candidate recipes at once
        let recipeIDs = recipes.compactMap(\.id)
        let favoriteSet: Set<UUID>
        if recipeIDs.isEmpty {
            favoriteSet = []
        } else {
            let favorites = try await UserFavorite.query(on: req.db)
                .filter(\.$user.$id == userID)
                .filter(\.$recipe.$id ~~ recipeIDs)
                .all()
            favoriteSet = Set(favorites.map { $0.$recipe.id })
        }

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
                    isFavorite: favoriteSet.contains(recipe.id!)
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
