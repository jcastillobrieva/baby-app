import Foundation
import Supabase

@Observable
final class SleepViewModel {
    var todaySessions: [SleepSession] = []
    var weeklyData: [DailySleepData] = []
    var isTracking = false
    var currentSessionStart: Date?
    var sleepType: SleepSession.SleepType = .night
    var showAddWaking = false
    var isLoading = false

    private var currentSessionId: UUID?
    private var babyId: UUID?
    private let supabase = SupabaseService.shared.client

    // MARK: - Load

    func loadSessions(babyId: UUID?) async {
        guard let babyId else { return }
        self.babyId = babyId

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let isoStart = DateFormatters.iso8601.string(from: startOfDay)

        do {
            let sessions: [SleepSession] = try await supabase
                .from("sleep_sessions")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .gte("start_time", value: isoStart)
                .order("start_time", ascending: false)
                .execute()
                .value

            todaySessions = sessions

            // Check for active session (no end_time)
            if let active = sessions.first(where: { $0.endTime == nil }) {
                isTracking = true
                currentSessionId = active.id
                currentSessionStart = active.startTime
            }
        } catch {
            // Log error, keep existing data
        }
    }

    // MARK: - Start/Stop

    func startSleep() async {
        guard let babyId else { return }

        do {
            let userId = try await supabase.auth.session.user.id

            let session: SleepSession = try await supabase
                .from("sleep_sessions")
                .insert([
                    "baby_id": babyId.uuidString,
                    "start_time": DateFormatters.iso8601.string(from: Date()),
                    "type": sleepType.rawValue,
                    "logged_by": userId.uuidString
                ])
                .select()
                .single()
                .execute()
                .value

            currentSessionId = session.id
            currentSessionStart = session.startTime
            isTracking = true
            todaySessions.insert(session, at: 0)
        } catch {
            // Handle error
        }
    }

    func stopSleep() async {
        guard let sessionId = currentSessionId else { return }

        do {
            let now = DateFormatters.iso8601.string(from: Date())

            try await supabase
                .from("sleep_sessions")
                .update(["end_time": now])
                .eq("id", value: sessionId.uuidString)
                .execute()

            isTracking = false
            currentSessionId = nil
            currentSessionStart = nil

            // Reload
            await loadSessions(babyId: babyId)
        } catch {
            // Handle error
        }
    }

    // MARK: - Wakings

    func addWaking(reason: SleepWaking.WakingReason?) async {
        guard let sessionId = currentSessionId else { return }

        do {
            var params: [String: String] = [
                "sleep_session_id": sessionId.uuidString,
                "time": DateFormatters.iso8601.string(from: Date())
            ]
            if let reason {
                params["reason"] = reason.rawValue
            }

            try await supabase
                .from("sleep_wakings")
                .insert(params)
                .execute()
        } catch {
            // Handle error
        }
    }

    // MARK: - Weekly Data

    func loadWeeklyData(babyId: UUID?) async {
        guard let babyId else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return }
        let isoStart = DateFormatters.iso8601.string(from: weekAgo)

        do {
            let sessions: [SleepSession] = try await supabase
                .from("sleep_sessions")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .gte("start_time", value: isoStart)
                .not("end_time", operator: .is, value: "null")
                .order("start_time")
                .execute()
                .value

            // Group by day
            var dailyMap: [Date: (night: Double, nap: Double)] = [:]
            for i in 0..<7 {
                let day = calendar.date(byAdding: .day, value: i, to: weekAgo)!
                dailyMap[calendar.startOfDay(for: day)] = (0, 0)
            }

            for session in sessions {
                guard let end = session.endTime else { continue }
                let day = calendar.startOfDay(for: session.startTime)
                let hours = end.timeIntervalSince(session.startTime) / 3600
                var entry = dailyMap[day] ?? (0, 0)
                if session.type == .night {
                    entry.night += hours
                } else {
                    entry.nap += hours
                }
                dailyMap[day] = entry
            }

            weeklyData = dailyMap
                .sorted { $0.key < $1.key }
                .map { day, hours in
                    DailySleepData(
                        date: day,
                        dayLabel: DateFormatters.shortDayMonth.string(from: day),
                        totalHours: hours.night + hours.nap,
                        nightHours: hours.night,
                        napHours: hours.nap
                    )
                }
        } catch {
            // Keep existing data
        }
    }
}
