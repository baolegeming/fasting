import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let startReminderID = "fastflow.startReminder"
    private let phaseReminderPrefix = "fastflow.phase."
    private let oneHourRemainingID = "fastflow.oneHourRemaining"

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func scheduleStartReminder(hour: Int, minute: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [startReminderID])
        let content = UNMutableNotificationContent()
        content.title = AppL10n.string("notification.start.title")
        content.body = AppL10n.string("notification.start.body")
        content.sound = .default

        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: startReminderID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelStartReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [startReminderID])
    }

    func reconcileStartReminder(enabled: Bool, hour: Int, minute: Int) {
        getAuthorizationStatus { [weak self] status in
            guard let self else { return }
            switch status {
            case .authorized, .provisional, .ephemeral:
                if enabled {
                    self.scheduleStartReminder(hour: hour, minute: minute)
                } else {
                    self.cancelStartReminder()
                }
            case .denied, .notDetermined:
                self.cancelStartReminder()
            @unknown default:
                self.cancelStartReminder()
            }
        }
    }

    func scheduleFastingNotifications(
        startAt: Date,
        elapsedSec: TimeInterval,
        targetDurationSec: Int,
        phases: [PhaseInfo],
        phasePushEnabled: Bool,
        oneHourPushEnabled: Bool
    ) {
        cancelAllFastingNotifications()

        if phasePushEnabled {
            for phase in phases where phase.lowerBoundSec > elapsedSec && phase.lowerBoundSec > 0 {
                schedulePhaseNotification(phase: phase, fireAt: startAt.addingTimeInterval(phase.lowerBoundSec))
            }
        }

        if oneHourPushEnabled, targetDurationSec > 3600 {
            let oneHourBefore = startAt.addingTimeInterval(TimeInterval(targetDurationSec - 3600))
            scheduleOneHourRemainingAlert(fireAt: oneHourBefore)
        }
    }

    private func schedulePhaseNotification(phase: PhaseInfo, fireAt: Date) {
        guard fireAt > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(phase.icon) \(phase.name)"
        content.subtitle = AppL10n.string("notification.phase.subtitle")
        content.body = phase.description
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = phaseReminderPrefix + phase.id
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleOneHourRemainingAlert(fireAt: Date) {
        guard fireAt > Date() else { return }
        center.removePendingNotificationRequests(withIdentifiers: [oneHourRemainingID])
        let content = UNMutableNotificationContent()
        content.title = AppL10n.string("notification.one_hour.title")
        content.body = AppL10n.string("notification.one_hour.body")
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: oneHourRemainingID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAllFastingNotifications() {
        let identifiers = [oneHourRemainingID] + PhaseInfo.notificationPhaseIDs.map { phaseReminderPrefix + $0 }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
