import Vapor
import Fluent

struct RecipeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let recipes = routes.grouped("recipes")
        recipes.get(use: listRecipes)
        recipes.get(":recipeID", use: getRecipe)
        recipes.get("popular", use: popularRecipes)
        recipes.get("recommended", use: recommendedRecipes)
        recipes.post(use: createRecipe)
        recipes.delete(":recipeID", use: deleteRecipe)
        recipes.post("favorites", use: addFavorite)
        recipes.delete("favorites", use: removeFavorite)
        recipes.get("favorites", use: listFavorites)
    }

    // MARK: - Helper: Build RecipeResponse from Model

    private func buildRecipeResponse(_ recipe: Recipe, isFavorite: Bool, includeIngredients: Bool = false) -> RecipeResponse {
        RecipeResponse(
            id: recipe.id!.uuidString,
            name: recipe.name,
            description: recipe.description,
            iconName: recipe.iconName,
            iconBackgroundColorHex: recipe.iconBackgroundColorHex,
            calories: recipe.calories,
            protein: recipe.proteinG,
            carbs: recipe.carbsG,
            fat: recipe.fatG,
            fiber: recipe.fiberG,
            cookingTime: recipe.cookingTimeMin,
            difficulty: recipe.difficulty.rawValue,
            servings: recipe.servings,
            price: Int(recipe.priceNtd),
            tags: recipe.tags.map { $0.tag.rawValue },
            allergens: recipe.allergens.map { $0.allergen },
            ingredients: includeIngredients ? recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder }).map {
                IngredientResponse(name: $0.name, amount: $0.amount)
            } : nil,
            steps: recipe.steps,
            cuisineType: recipe.cuisineType?.rawValue,
            imageUrl: recipe.imageURL,
            imageBase64: recipe.imageBase64,
            audioUrl: recipe.audioURL,
            authorId: recipe.$author.id?.uuidString,
            authorName: nil,
            isFavorite: isFavorite,
            createdAt: recipe.createdAt
        )
    }

    // MARK: - GET /recipes
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
            .with(\.$allergens)
            .range(lower: (page - 1) * limit, upper: page * limit)
            .all()

        // Only query favorites for the recipe IDs on this page
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
            buildRecipeResponse(recipe, isFavorite: favoriteSet.contains(recipe.id!))
        }

        let body = PagedResponse(
            items: items,
            page: page,
            perPage: limit,
            total: total,
            totalPages: max(1, (total + limit - 1) / limit)
        )

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
            .with(\.$allergens)
            .first() else {
            throw Abort(.notFound, reason: "Recipe not found")
        }

        // Only allow viewing if published or if the user is the author
        guard recipe.isPublished || recipe.$author.id == userID else {
            throw Abort(.notFound, reason: "Recipe not found")
        }

        let isFavorite = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$recipe.$id == recipeID)
            .first() != nil

        let body = buildRecipeResponse(recipe, isFavorite: isFavorite, includeIngredients: true)

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
            .with(\.$allergens)
            .limit(20)
            .all()

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
            buildRecipeResponse(recipe, isFavorite: favoriteSet.contains(recipe.id!))
        }

        let response = try await body.encodeResponse(for: req)
        response.headers.replaceOrAdd(name: .cacheControl, value: "public, max-age=300")
        return response
    }

    // MARK: - GET /recipes/recommended
    @Sendable
    func recommendedRecipes(req: Request) async throws -> [RecipeResponse] {
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
            .with(\.$allergens)
            .limit(30)
            .all()

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

        let items: [RecipeResponse] = recipes.compactMap { recipe in
            var matched = false
            if proteinGap > 10 && recipe.proteinG > 15 {
                matched = true
            } else if fiberGap > 5 && recipe.fiberG > 5 {
                matched = true
            } else if caloriesRemaining > 300 && recipe.calories <= Int(caloriesRemaining) {
                matched = true
            }

            guard matched else { return nil }

            return buildRecipeResponse(recipe, isFavorite: favoriteSet.contains(recipe.id!))
        }

        return items
    }

    // MARK: - POST /recipes (NEW: create recipe)
    @Sendable
    func createRecipe(req: Request) async throws -> RecipeResponse {
        let userID = try req.authenticatedUserID
        try CreateRecipeRequest.validate(content: req)
        let body = try req.content.decode(CreateRecipeRequest.self)

        // Validate imageBase64 size (max 5MB)
        if let base64 = body.imageBase64, base64.count > 5_000_000 {
            throw Abort(.badRequest, reason: "image_base64 exceeds maximum size of 5MB")
        }

        let difficulty: RecipeDifficulty
        if let diffStr = body.difficulty, let d = RecipeDifficulty(rawValue: diffStr) {
            difficulty = d
        } else {
            difficulty = .easy
        }

        let cuisineType: CuisineTypeDB?
        if let ct = body.cuisineType {
            cuisineType = CuisineTypeDB(rawValue: ct) ?? CuisineTypeDB(chinese: ct)
        } else {
            cuisineType = nil
        }

        let recipe = Recipe(
            name: body.name,
            calories: body.calories,
            cookingTimeMin: body.cookingTime,
            difficulty: difficulty,
            servings: body.servings ?? 2,
            priceNtd: Double(body.price ?? 0),
            proteinG: body.protein ?? 0,
            carbsG: body.carbs ?? 0,
            fatG: body.fat ?? 0,
            fiberG: body.fiber ?? 0,
            cuisineType: cuisineType,
            isPublished: true
        )
        recipe.description = body.description
        recipe.iconName = body.iconName
        recipe.iconBackgroundColorHex = body.iconBackgroundColorHex
        recipe.steps = body.steps
        recipe.imageURL = body.imageUrl
        recipe.imageBase64 = body.imageBase64
        recipe.audioURL = body.audioUrl
        recipe.$author.id = userID

        try await recipe.save(on: req.db)

        let recipeID = recipe.id!

        // Create ingredients
        if let ingredients = body.ingredients {
            for (index, ing) in ingredients.enumerated() {
                let ingredient = RecipeIngredient(
                    recipeID: recipeID,
                    name: ing.name,
                    amount: ing.amount,
                    unit: ing.unit,
                    sortOrder: index
                )
                try await ingredient.save(on: req.db)
            }
        }

        // Create tags
        if let tags = body.tags {
            for tagStr in tags {
                if let tag = RecipeTagDB(rawValue: tagStr) {
                    let tagModel = RecipeTagModel(recipeID: recipeID, tag: tag)
                    try await tagModel.save(on: req.db)
                }
            }
        }

        // Create allergens
        if let allergens = body.allergens {
            for allergenStr in allergens {
                let allergen = RecipeAllergen(recipeID: recipeID, allergen: allergenStr)
                try await allergen.save(on: req.db)
            }
        }

        // Reload with relations for response
        let loaded = try await Recipe.query(on: req.db)
            .filter(\.$id == recipeID)
            .with(\.$tags)
            .with(\.$ingredients)
            .with(\.$allergens)
            .first()!

        return buildRecipeResponse(loaded, isFavorite: false, includeIngredients: true)
    }

    // MARK: - DELETE /recipes/:recipeID (NEW: delete recipe)
    @Sendable
    func deleteRecipe(req: Request) async throws -> SuccessResponse {
        let userID = try req.authenticatedUserID
        guard let recipeID = req.parameters.get("recipeID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let recipe = try await Recipe.query(on: req.db)
            .filter(\.$id == recipeID)
            .first() else {
            throw Abort(.notFound, reason: "Recipe not found")
        }

        // Authorization: only the author can delete
        guard recipe.$author.id == userID else {
            throw Abort(.forbidden, reason: "You can only delete your own recipes")
        }

        try await req.db.transaction { db in
            try await RecipeIngredient.query(on: db).filter(\.$recipe.$id == recipe.id!).delete(force: true)
            try await RecipeTagModel.query(on: db).filter(\.$recipe.$id == recipe.id!).delete(force: true)
            try await RecipeAllergen.query(on: db).filter(\.$recipe.$id == recipe.id!).delete(force: true)
            try await UserFavorite.query(on: db).filter(\.$recipe.$id == recipe.id!).delete(force: true)
            try await recipe.delete(force: true, on: db)
        }
        return SuccessResponse(message: "Recipe deleted")
    }

    // MARK: - POST /recipes/favorites (body-based)
    @Sendable
    func addFavorite(req: Request) async throws -> SuccessResponse {
        let userID = try req.authenticatedUserID
        try FavoriteRequest.validate(content: req)
        let body = try req.content.decode(FavoriteRequest.self)

        guard let recipeID = UUID(uuidString: body.recipeId) else {
            throw Abort(.badRequest, reason: "Invalid recipe_id format")
        }

        // Verify recipe exists and is published before allowing favorite
        guard let _ = try await Recipe.query(on: req.db)
            .filter(\.$id == recipeID)
            .filter(\.$isPublished == true)
            .first() else {
            throw Abort(.notFound, reason: "Recipe not found")
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

    // MARK: - DELETE /recipes/favorites (body-based)
    @Sendable
    func removeFavorite(req: Request) async throws -> SuccessResponse {
        let userID = try req.authenticatedUserID
        try FavoriteRequest.validate(content: req)
        let body = try req.content.decode(FavoriteRequest.self)

        guard let recipeID = UUID(uuidString: body.recipeId) else {
            throw Abort(.badRequest, reason: "Invalid recipe_id format")
        }

        try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$recipe.$id == recipeID)
            .delete()

        return SuccessResponse(message: "Removed from favorites")
    }

    // MARK: - GET /recipes/favorites
    @Sendable
    func listFavorites(req: Request) async throws -> FavoritesListResponse {
        let userID = try req.authenticatedUserID

        let favorites = try await UserFavorite.query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()

        let favoriteIDs = favorites.map { $0.$recipe.id }

        return FavoritesListResponse(recipeIds: favoriteIDs.map { $0.uuidString })
    }
}
