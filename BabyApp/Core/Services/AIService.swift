import Foundation
import Supabase
import os

private let logger = Logger(subsystem: "com.babyapp", category: "ai")

@Observable
final class AIService {
    private let supabase = SupabaseService.shared.client

    var isLoading = false

    // MARK: - Chat

    struct ChatResponse: Codable {
        let conversationId: UUID?
        let message: String
        let usage: TokenUsage?
    }

    func sendMessage(
        babyId: UUID,
        conversationId: UUID?,
        message: String
    ) async throws -> ChatResponse {
        isLoading = true
        defer { isLoading = false }

        logger.info("Sending chat message for baby \(babyId)")

        var params: [String: String] = [
            "babyId": babyId.uuidString,
            "message": message
        ]
        if let convId = conversationId {
            params["conversationId"] = convId.uuidString
        }

        let response: ChatResponse = try await supabase.functions
            .invoke("ai-chat", options: .init(body: params))

        return response
    }

    // MARK: - Meal Plan

    struct MealPlanResponse: Codable {
        let plan: MealPlanData?
        let rawContent: String
        let usage: TokenUsage?
    }

    struct MealPlanData: Codable {
        let plan: [MealDay]?
        let newFoodsToIntroduce: [NewFood]?
        let tips: String?
    }

    struct MealDay: Codable {
        let day: Int
        let dayName: String
        let meals: [MealItem]
    }

    struct MealItem: Codable {
        let mealType: String
        let foodName: String
        let preparation: String?
        let amount: String?
        let notes: String?
    }

    struct NewFood: Codable {
        let foodName: String
        let suggestedDay: String?
        let reason: String?
    }

    func generateMealPlan(
        babyId: UUID,
        weekStart: String?,
        preferences: String?
    ) async throws -> MealPlanResponse {
        isLoading = true
        defer { isLoading = false }

        logger.info("Generating meal plan for baby \(babyId)")

        var params: [String: String] = ["babyId": babyId.uuidString]
        if let ws = weekStart { params["weekStart"] = ws }
        if let prefs = preferences { params["preferences"] = prefs }

        let response: MealPlanResponse = try await supabase.functions
            .invoke("ai-meal-plan", options: .init(body: params))

        return response
    }

    // MARK: - Grocery List

    struct GroceryListResponse: Codable {
        let groceryList: GroceryListData?
        let rawContent: String
        let usage: TokenUsage?
    }

    struct GroceryListData: Codable {
        let categories: [GroceryCategory]
        let tips: String?
    }

    struct GroceryCategory: Codable, Identifiable {
        let name: String
        let items: [GroceryItem]

        var id: String { name }
    }

    struct GroceryItem: Codable, Identifiable {
        let name: String
        let quantity: String?
        let notes: String?

        var id: String { name }
    }

    func generateGroceryList(
        babyId: UUID,
        mealPlanId: UUID
    ) async throws -> GroceryListResponse {
        isLoading = true
        defer { isLoading = false }

        logger.info("Generating grocery list for meal plan \(mealPlanId)")

        let params: [String: String] = [
            "babyId": babyId.uuidString,
            "mealPlanId": mealPlanId.uuidString
        ]

        let response: GroceryListResponse = try await supabase.functions
            .invoke("ai-grocery-list", options: .init(body: params))

        return response
    }

    // MARK: - Weekly Summary

    struct WeeklySummaryResponse: Codable {
        let summary: String
        let conversationId: UUID?
        let usage: TokenUsage?
    }

    func generateWeeklySummary(babyId: UUID) async throws -> WeeklySummaryResponse {
        isLoading = true
        defer { isLoading = false }

        logger.info("Generating weekly summary for baby \(babyId)")

        let params: [String: String] = ["babyId": babyId.uuidString]

        let response: WeeklySummaryResponse = try await supabase.functions
            .invoke("ai-weekly-summary", options: .init(body: params))

        return response
    }

    // MARK: - Development Tips

    struct DevelopmentTipsResponse: Codable {
        let tips: String
        let usage: TokenUsage?
    }

    func generateDevelopmentTips(
        babyId: UUID,
        category: String? = nil
    ) async throws -> DevelopmentTipsResponse {
        isLoading = true
        defer { isLoading = false }

        logger.info("Generating development tips for baby \(babyId)")

        var params: [String: String] = ["babyId": babyId.uuidString]
        if let cat = category { params["category"] = cat }

        let response: DevelopmentTipsResponse = try await supabase.functions
            .invoke("ai-development-tips", options: .init(body: params))

        return response
    }
}

// MARK: - Shared Types

struct TokenUsage: Codable {
    let inputTokens: Int?
    let outputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}
