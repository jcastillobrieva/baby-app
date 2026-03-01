import Foundation
import Supabase

@Observable
final class DiaperViewModel {
    var todayLogs: [DiaperLog] = []
    var isLoading = false

    // Optional details
    var consistency: DiaperLog.Consistency?
    var color: DiaperLog.DiaperColor?
    var hasBlood = false
    var hasMucus = false

    // Computed counts
    var wetCount: Int { todayLogs.filter { $0.type == .wet }.count }
    var dirtyCount: Int { todayLogs.filter { $0.type == .dirty }.count }
    var bothCount: Int { todayLogs.filter { $0.type == .both }.count }

    private var babyId: UUID?
    private let supabase = SupabaseService.shared.client

    // MARK: - Load

    func loadLogs(babyId: UUID?) async {
        guard let babyId else { return }
        self.babyId = babyId

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let isoStart = DateFormatters.iso8601.string(from: startOfDay)

        do {
            let logs: [DiaperLog] = try await supabase
                .from("diaper_logs")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .gte("changed_at", value: isoStart)
                .order("changed_at", ascending: false)
                .execute()
                .value

            todayLogs = logs
        } catch {
            // Keep existing data
        }
    }

    // MARK: - Log

    func logDiaper(type: DiaperLog.DiaperType) async {
        guard let babyId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await supabase.auth.session.user.id

            var params: [String: String] = [
                "baby_id": babyId.uuidString,
                "type": type.rawValue,
                "has_blood": String(hasBlood),
                "has_mucus": String(hasMucus),
                "changed_at": DateFormatters.iso8601.string(from: Date()),
                "logged_by": userId.uuidString
            ]

            if let consistency {
                params["consistency"] = consistency.rawValue
            }
            if let color {
                params["color"] = color.rawValue
            }

            try await supabase
                .from("diaper_logs")
                .insert(params)
                .execute()

            // Reset optional fields
            consistency = nil
            color = nil
            hasBlood = false
            hasMucus = false

            await loadLogs(babyId: babyId)
            NotificationService.shared.scheduleDiaperReminder()
        } catch {
            // Handle error
        }
    }
}
