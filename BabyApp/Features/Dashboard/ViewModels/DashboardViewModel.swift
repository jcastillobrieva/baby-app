import Foundation
import Supabase

@Observable
final class DashboardViewModel {
    var todaySleepHours = "0h"
    var todayFeedingCount = 0
    var todayDiaperCount = 0
    var lastLogTime = "--"

    var showSleepLog = false
    var showFeedingLog = false
    var showDiaperLog = false

    private let supabase = SupabaseService.shared.client

    func loadTodayData(babyId: UUID?) async {
        guard let babyId else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let isoStart = DateFormatters.iso8601.string(from: startOfDay)

        // Load all counts in parallel
        async let sleepTask = loadSleepHours(babyId: babyId, since: isoStart)
        async let feedingTask = loadFeedingCount(babyId: babyId, since: isoStart)
        async let diaperTask = loadDiaperCount(babyId: babyId, since: isoStart)

        let (sleep, feeding, diaper) = await (sleepTask, feedingTask, diaperTask)

        todaySleepHours = sleep
        todayFeedingCount = feeding
        todayDiaperCount = diaper
    }

    private func loadSleepHours(babyId: UUID, since: String) async -> String {
        do {
            let sessions: [SleepSession] = try await supabase
                .from("sleep_sessions")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .gte("start_time", value: since)
                .execute()
                .value

            let totalMinutes = sessions.compactMap(\.durationMinutes).reduce(0, +)
            return DateFormatters.formatDuration(minutes: totalMinutes)
        } catch {
            return "0h"
        }
    }

    private func loadFeedingCount(babyId: UUID, since: String) async -> Int {
        do {
            let logs: [FeedingLog] = try await supabase
                .from("feeding_logs")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .gte("start_time", value: since)
                .execute()
                .value
            return logs.count
        } catch {
            return 0
        }
    }

    private func loadDiaperCount(babyId: UUID, since: String) async -> Int {
        do {
            let logs: [DiaperLog] = try await supabase
                .from("diaper_logs")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .gte("changed_at", value: since)
                .execute()
                .value
            return logs.count
        } catch {
            return 0
        }
    }
}
