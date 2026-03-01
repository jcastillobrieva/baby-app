import Foundation
import UserNotifications
import os

private let logger = Logger(subsystem: "com.babyapp", category: "notifications")

final class NotificationService: Sendable {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            logger.info("Notification permission: \(granted)")
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error)")
            return false
        }
    }

    // MARK: - Feeding Reminders

    func scheduleFeedingReminder(afterMinutes minutes: Int = 180) {
        let content = UNMutableNotificationContent()
        content.title = "Hora de comer"
        content.body = "Han pasado \(minutes / 60) horas desde la última alimentación."
        content.sound = .default
        content.categoryIdentifier = "FEEDING_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "feeding-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to schedule feeding reminder: \(error)")
            } else {
                logger.info("Feeding reminder scheduled for \(minutes) minutes")
            }
        }
    }

    // MARK: - Diaper Reminders

    func scheduleDiaperReminder(afterMinutes minutes: Int = 120) {
        let content = UNMutableNotificationContent()
        content.title = "Revisar pañal"
        content.body = "Han pasado \(minutes / 60) horas desde el último cambio."
        content.sound = .default
        content.categoryIdentifier = "DIAPER_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "diaper-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to schedule diaper reminder: \(error)")
            } else {
                logger.info("Diaper reminder scheduled for \(minutes) minutes")
            }
        }
    }

    // MARK: - Sleep Reminders

    func scheduleBedtimeReminder(hour: Int = 19, minute: Int = 30) {
        let content = UNMutableNotificationContent()
        content.title = "Hora de la rutina de dormir"
        content.body = "Es hora de comenzar la rutina de sueño."
        content.sound = .default
        content.categoryIdentifier = "BEDTIME_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "bedtime-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to schedule bedtime reminder: \(error)")
            } else {
                logger.info("Bedtime reminder scheduled for \(hour):\(minute)")
            }
        }
    }

    // MARK: - Allergy Watch

    func scheduleAllergyCheckReminder(foodName: String, afterHours hours: Int = 72) {
        let content = UNMutableNotificationContent()
        content.title = "Monitoreo de alergia"
        content.body = "Han pasado 3 días desde que \(foodName) fue introducido. ¿Hubo alguna reacción?"
        content.sound = .default
        content.categoryIdentifier = "ALLERGY_CHECK"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(hours * 3600),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "allergy-check-\(foodName)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to schedule allergy check for \(foodName): \(error)")
            } else {
                logger.info("Allergy check reminder scheduled for \(foodName)")
            }
        }
    }

    // MARK: - Cancel

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("All reminders cancelled")
    }

    func cancelReminder(identifier: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
