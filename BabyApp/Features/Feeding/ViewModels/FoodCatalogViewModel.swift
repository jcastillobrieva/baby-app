import Foundation
import Supabase

@Observable
final class FoodCatalogViewModel {
    var foods: [FoodCatalogItem] = []

    var approvedCount: Int { foods.filter { $0.status == .approved }.count }
    var untriedCount: Int { foods.filter { $0.status == .untried }.count }
    var watchCount: Int { foods.filter { $0.status == .watch }.count }
    var avoidCount: Int { foods.filter { $0.status == .avoid }.count }

    private var babyId: UUID?
    private let supabase = SupabaseService.shared.client

    func filteredFoods(status: FoodCatalogItem.FoodStatus?) -> [FoodCatalogItem] {
        guard let status else { return foods }
        return foods.filter { $0.status == status }
    }

    // MARK: - Load

    func loadCatalog(babyId: UUID?) async {
        guard let babyId else { return }
        self.babyId = babyId

        do {
            let items: [FoodCatalogItem] = try await supabase
                .from("food_catalog")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .order("food_name")
                .execute()
                .value

            foods = items
        } catch {
            // Keep existing
        }
    }

    // MARK: - Update Status

    func updateStatus(food: FoodCatalogItem, newStatus: FoodCatalogItem.FoodStatus) async {
        do {
            try await supabase
                .from("food_catalog")
                .update(["status": newStatus.rawValue])
                .eq("id", value: food.id.uuidString)
                .execute()

            await loadCatalog(babyId: babyId)
        } catch {
            // Handle error
        }
    }

    // MARK: - Add Food

    func addFood(name: String, category: FoodCatalogItem.FoodCategory) async {
        guard let babyId else { return }

        do {
            try await supabase
                .from("food_catalog")
                .insert([
                    "baby_id": babyId.uuidString,
                    "food_name": name,
                    "category": category.rawValue,
                    "status": "untried"
                ])
                .execute()

            await loadCatalog(babyId: babyId)
        } catch {
            // Handle error (might be duplicate)
        }
    }
}
