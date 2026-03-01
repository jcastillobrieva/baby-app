import Foundation
import Supabase
import os

private let logger = Logger(subsystem: "com.babyapp", category: "sync")

/// Handles Supabase Realtime subscriptions and offline queue.
@Observable
final class SyncService {
    private let supabase = SupabaseService.shared.client
    private var channels: [RealtimeChannelV2] = []

    var isConnected = false

    // MARK: - Realtime Subscriptions

    /// Subscribe to changes for a specific baby's data.
    func subscribeToFamily(familyId: UUID) async {
        logger.info("Subscribing to realtime for family \(familyId)")

        let channel = supabase.realtimeV2.channel("family-\(familyId.uuidString)")

        // Listen for changes on key tables
        let sleepChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "sleep_sessions"
        )

        let feedingChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "feeding_logs"
        )

        let diaperChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "diaper_logs"
        )

        await channel.subscribe()
        channels.append(channel)
        isConnected = true

        // Process changes in background tasks
        Task {
            for await change in sleepChanges {
                logger.debug("Sleep change received: \(String(describing: change.rawMessage))")
                await handleDataChange(table: "sleep_sessions")
            }
        }

        Task {
            for await change in feedingChanges {
                logger.debug("Feeding change received: \(String(describing: change.rawMessage))")
                await handleDataChange(table: "feeding_logs")
            }
        }

        Task {
            for await change in diaperChanges {
                logger.debug("Diaper change received: \(String(describing: change.rawMessage))")
                await handleDataChange(table: "diaper_logs")
            }
        }

        logger.info("Realtime subscriptions active for family \(familyId)")
    }

    func unsubscribeAll() async {
        for channel in channels {
            await channel.unsubscribe()
        }
        channels.removeAll()
        isConnected = false
        logger.info("Unsubscribed from all realtime channels")
    }

    // MARK: - Change Handling

    private func handleDataChange(table: String) async {
        // Post notification for UI to refresh
        await MainActor.run {
            NotificationCenter.default.post(
                name: .dataDidChange,
                object: nil,
                userInfo: ["table": table]
            )
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let dataDidChange = Notification.Name("BabyApp.dataDidChange")
}
