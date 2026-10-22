import Foundation
import PolyCore
import UserNotifications

/// Puts the reminders of the plan in the place of the reminders that the app
/// asked for before.
enum Notifications {
    /// Asks the user one time if the app can show notifications.
    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func reschedule(_ data: AppData) {
        let reminders = ReminderPlan.reminders(exams: data.exams, after: .now)
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let calendar = Week.calendar
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = title(reminder)
            content.body = body(reminder)
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }

    static func title(_ reminder: Reminder) -> String {
        switch reminder.kind {
        case .exam(days: 1): tr("Exam tomorrow: %@", reminder.title)
        case let .exam(days): tr("Exam in %d days: %@", days, reminder.title)
        }
    }

    static func body(_ reminder: Reminder) -> String {
        reminder.place.isEmpty ? tr("Good luck.") : tr("Room %@. Good luck.", reminder.place)
    }
}
