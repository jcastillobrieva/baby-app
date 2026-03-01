import Foundation
import Supabase

@Observable
final class PlanningViewModel {
    var selectedDate = Date()
    var planItems: [PlanItem] = []
    var showAddItem = false

    private var dailyPlanId: UUID?
    private var babyId: UUID?
    private let supabase = SupabaseService.shared.client

    // MARK: - Load

    func loadPlan(babyId: UUID?) async {
        guard let babyId else { return }
        self.babyId = babyId

        let dateString = DateFormatters.dateOnly.string(from: selectedDate)

        do {
            // Try to find existing plan
            let plans: [DailyPlan] = try await supabase
                .from("daily_plans")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .eq("date", value: dateString)
                .execute()
                .value

            if let plan = plans.first {
                dailyPlanId = plan.id

                let items: [PlanItem] = try await supabase
                    .from("plan_items")
                    .select()
                    .eq("daily_plan_id", value: plan.id.uuidString)
                    .order("sort_order")
                    .execute()
                    .value

                planItems = items
            } else {
                dailyPlanId = nil
                planItems = []
            }
        } catch {
            // Keep existing
        }
    }

    // MARK: - Toggle

    func toggleItem(_ item: PlanItem) async {
        do {
            let newCompleted = !item.completed
            var params: [String: String] = [
                "completed": String(newCompleted)
            ]
            if newCompleted {
                params["completed_at"] = DateFormatters.iso8601.string(from: Date())
            }

            try await supabase
                .from("plan_items")
                .update(params)
                .eq("id", value: item.id.uuidString)
                .execute()

            await loadPlan(babyId: babyId)
        } catch {
            // Handle error
        }
    }
}

// MARK: - Daily Plan Model

struct DailyPlan: Codable, Identifiable {
    let id: UUID
    let babyId: UUID
    let date: String
    let templateName: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case babyId = "baby_id"
        case date
        case templateName = "template_name"
        case notes
    }
}
