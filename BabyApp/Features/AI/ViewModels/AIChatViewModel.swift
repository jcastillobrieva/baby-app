import Foundation

struct ChatMessageUI: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

@Observable
final class AIChatViewModel {
    var messages: [ChatMessageUI] = []
    var inputText = ""
    var isLoading = false
    var babyId: UUID?

    private var conversationId: UUID?
    private let aiService = AIService()

    init() {
        // Welcome message
        messages.append(ChatMessageUI(
            content: "Hola! Soy tu asistente de cuidado infantil. Puedo ayudarte con nutrición, desarrollo, rutinas de sueño y más. ¿En qué puedo ayudarte?",
            isUser: false,
            timestamp: Date()
        ))
    }

    // MARK: - Send Message

    func sendMessage() async {
        guard let babyId, !inputText.isEmpty else { return }

        let userMessage = inputText
        inputText = ""

        messages.append(ChatMessageUI(
            content: userMessage,
            isUser: true,
            timestamp: Date()
        ))

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await aiService.sendMessage(
                babyId: babyId,
                conversationId: conversationId,
                message: userMessage
            )

            conversationId = response.conversationId

            messages.append(ChatMessageUI(
                content: response.message,
                isUser: false,
                timestamp: Date()
            ))
        } catch {
            messages.append(ChatMessageUI(
                content: "Lo siento, hubo un error. Intenta de nuevo.",
                isUser: false,
                timestamp: Date()
            ))
        }
    }

    // MARK: - Quick Actions

    func generateMealPlan() async {
        guard let babyId else { return }
        isLoading = true
        defer { isLoading = false }

        messages.append(ChatMessageUI(
            content: "Genera un plan de comidas para esta semana",
            isUser: true,
            timestamp: Date()
        ))

        do {
            let response = try await aiService.generateMealPlan(
                babyId: babyId,
                weekStart: nil,
                preferences: nil
            )

            messages.append(ChatMessageUI(
                content: response.rawContent,
                isUser: false,
                timestamp: Date()
            ))
        } catch {
            messages.append(ChatMessageUI(
                content: "No pude generar el plan de comidas. Intenta de nuevo.",
                isUser: false,
                timestamp: Date()
            ))
        }
    }

    func generateWeeklySummary() async {
        guard let babyId else { return }
        isLoading = true
        defer { isLoading = false }

        messages.append(ChatMessageUI(
            content: "Genera el resumen semanal",
            isUser: true,
            timestamp: Date()
        ))

        do {
            let response = try await aiService.generateWeeklySummary(babyId: babyId)

            messages.append(ChatMessageUI(
                content: response.summary,
                isUser: false,
                timestamp: Date()
            ))
        } catch {
            messages.append(ChatMessageUI(
                content: "No pude generar el resumen. Intenta de nuevo.",
                isUser: false,
                timestamp: Date()
            ))
        }
    }

    func generateDevelopmentTips() async {
        guard let babyId else { return }
        isLoading = true
        defer { isLoading = false }

        messages.append(ChatMessageUI(
            content: "Dame tips de desarrollo para la edad de mi bebé",
            isUser: true,
            timestamp: Date()
        ))

        do {
            let response = try await aiService.generateDevelopmentTips(babyId: babyId)

            messages.append(ChatMessageUI(
                content: response.tips,
                isUser: false,
                timestamp: Date()
            ))
        } catch {
            messages.append(ChatMessageUI(
                content: "No pude generar los tips. Intenta de nuevo.",
                isUser: false,
                timestamp: Date()
            ))
        }
    }

    func generateGroceryList() async {
        // This requires an existing meal plan — show message
        messages.append(ChatMessageUI(
            content: "Genera la lista de mercado",
            isUser: true,
            timestamp: Date()
        ))

        messages.append(ChatMessageUI(
            content: "Para generar la lista de mercado, primero necesitas un plan de comidas activo. Usa 'Plan semanal' para crear uno.",
            isUser: false,
            timestamp: Date()
        ))
    }
}
