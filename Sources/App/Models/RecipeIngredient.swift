import Fluent
import Vapor

/// Corresponds to iOS `Ingredient` in Recipe.swift
final class RecipeIngredient: Model, Content, @unchecked Sendable {
    static let schema = "recipe_ingredients"

    @ID(key: .id) var id: UUID?
    @Parent(key: "recipe_id") var recipe: Recipe
    @Field(key: "name") var name: String
    @Field(key: "amount") var amount: String
    @Field(key: "unit") var unit: String?
    @Field(key: "sort_order") var sortOrder: Int

    init() {}

    init(
        id: UUID? = nil,
        recipeID: UUID,
        name: String,
        amount: String,
        unit: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.$recipe.id = recipeID
        self.name = name
        self.amount = amount
        self.unit = unit
        self.sortOrder = sortOrder
    }
}
