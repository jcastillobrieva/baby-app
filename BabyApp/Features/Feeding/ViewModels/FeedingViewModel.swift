import Foundation
import Supabase

@Observable
final class FeedingViewModel {
    // State
    var todayLogs: [FeedingLog] = []
    var isLoading = false

    // Bottle
    var bottleOz: Double = 4.0

    // Breast
    var breastSide: FeedingLog.BreastSide = .left
    var isBreastfeeding = false
    var breastfeedingElapsed = 0
    private var breastfeedingStart: Date?
    private var breastfeedingTimer: Timer?

    // Solid
    var solidFoodName = ""
    var solidPreparation: SolidFoodLog.Preparation = .puree
    var solidAmount: SolidFoodLog.Amount = .small
    var solidReaction: SolidFoodLog.Reaction = .none

    private var babyId: UUID?
    private let supabase = SupabaseService.shared.client

    // MARK: - Load

    func loadLogs(babyId: UUID?) async {
        guard let babyId else { return }
        self.babyId = babyId

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let isoStart = DateFormatters.iso8601.string(from: startOfDay)

        do {
            let logs: [FeedingLog] = try await supabase
                .from("feeding_logs")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .gte("start_time", value: isoStart)
                .order("start_time", ascending: false)
                .execute()
                .value

            todayLogs = logs
        } catch {
            // Keep existing data
        }
    }

    // MARK: - Bottle

    func logBottle() async {
        guard let babyId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await supabase.auth.session.user.id

            try await supabase
                .from("feeding_logs")
                .insert([
                    "baby_id": babyId.uuidString,
                    "type": "bottle",
                    "amount_oz": String(bottleOz),
                    "start_time": DateFormatters.iso8601.string(from: Date()),
                    "logged_by": userId.uuidString
                ])
                .execute()

            await loadLogs(babyId: babyId)
            NotificationService.shared.scheduleFeedingReminder()
        } catch {
            // Handle error
        }
    }

    // MARK: - Breastfeeding

    func startBreastfeeding() async {
        guard let babyId else { return }

        do {
            let userId = try await supabase.auth.session.user.id

            let log: FeedingLog = try await supabase
                .from("feeding_logs")
                .insert([
                    "baby_id": babyId.uuidString,
                    "type": "breast",
                    "breast_side": breastSide.rawValue,
                    "start_time": DateFormatters.iso8601.string(from: Date()),
                    "logged_by": userId.uuidString
                ])
                .select()
                .single()
                .execute()
                .value

            isBreastfeeding = true
            breastfeedingStart = Date()
            breastfeedingElapsed = 0

            // Start timer on main thread
            await MainActor.run {
                breastfeedingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    guard let self, let start = self.breastfeedingStart else { return }
                    self.breastfeedingElapsed = Int(Date().timeIntervalSince(start))
                }
            }

            todayLogs.insert(log, at: 0)
        } catch {
            // Handle error
        }
    }

    func stopBreastfeeding() async {
        guard let babyId else { return }
        guard let latestBreast = todayLogs.first(where: { $0.type == .breast && $0.endTime == nil }) else { return }

        breastfeedingTimer?.invalidate()
        breastfeedingTimer = nil

        let now = Date()
        let duration = breastfeedingStart.map { Int(now.timeIntervalSince($0) / 60) } ?? 0

        do {
            try await supabase
                .from("feeding_logs")
                .update([
                    "end_time": DateFormatters.iso8601.string(from: now),
                    "duration_minutes": String(duration)
                ])
                .eq("id", value: latestBreast.id.uuidString)
                .execute()

            isBreastfeeding = false
            breastfeedingStart = nil
            breastfeedingElapsed = 0

            await loadLogs(babyId: babyId)
            NotificationService.shared.scheduleFeedingReminder()
        } catch {
            // Handle error
        }
    }

    // MARK: - Solid Food

    func logSolidFood() async {
        guard let babyId, !solidFoodName.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await supabase.auth.session.user.id

            try await supabase
                .from("solid_food_logs")
                .insert([
                    "baby_id": babyId.uuidString,
                    "food_name": solidFoodName,
                    "preparation": solidPreparation.rawValue,
                    "amount": solidAmount.rawValue,
                    "reaction": solidReaction.rawValue,
                    "eaten_at": DateFormatters.iso8601.string(from: Date()),
                    "logged_by": userId.uuidString
                ])
                .execute()

            // Update food catalog
            await updateFoodCatalog(foodName: solidFoodName)

            // Schedule allergy watch if new food
            if solidReaction != .allergic {
                NotificationService.shared.scheduleAllergyCheckReminder(foodName: solidFoodName)
            }

            solidFoodName = ""
            solidReaction = .none
        } catch {
            // Handle error
        }
    }

    private func updateFoodCatalog(foodName: String) async {
        guard let babyId else { return }

        do {
            // Check if food exists in catalog
            let existing: [FoodCatalogItem] = try await supabase
                .from("food_catalog")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .eq("food_name", value: foodName)
                .execute()
                .value

            if existing.isEmpty {
                // Add to catalog as approved (or watch if allergic reaction)
                let status = solidReaction == .allergic ? "watch" : "approved"
                let watchUntil = solidReaction != .allergic
                    ? DateFormatters.iso8601.string(from: Date().addingTimeInterval(3 * 24 * 3600))
                    : nil

                var params: [String: String] = [
                    "baby_id": babyId.uuidString,
                    "food_name": foodName,
                    "category": "other",
                    "status": status,
                    "first_tried_at": DateFormatters.iso8601.string(from: Date())
                ]
                if let watchUntil {
                    params["allergy_watch_until"] = watchUntil
                }

                try await supabase
                    .from("food_catalog")
                    .insert(params)
                    .execute()
            }
        } catch {
            // Non-critical, just catalog update
        }
    }
}
