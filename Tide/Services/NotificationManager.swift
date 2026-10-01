
//  SERVICE
//  Handles the reminder notifications:
//  - a heads-up 3 days before predicted period
//  - a daily "due today" / "X days late" reminder for 10 days, with a
//    "Log Period Start" button you can tap without opening the app
//
//  App only
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    /// The one shared NotificationManager the whole app uses.
    static let shared = NotificationManager()

    /// Set by TideApp while the app is open, so a log from a notification
    /// shows up on screen straight away. nil if iOS started the app in the
    /// background just to handle the notification button.
    var viewModel: CycleViewModel? = nil

    // Names iOS uses to tell our notifications and button apart.
    static let categoryID = "PERIOD_REMINDER"
    static let logButtonID = "LOG_PERIOD_ACTION"
    static let dailyReminderID = "tide.periodReminder."
    static let headsUpID = "tide.headsUpReminder"

    /// How many days before the predicted date the heads-up fires.
    static let headsUpDaysBefore = 3

    /// How many daily reminders to schedule (due today + 9 days late).
    static let numberOfDailyReminders = 10

    // MARK: - Setup

    /// Adds the "Log Period Start" button to our reminders.
    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // No .foreground option, so tapping it doesn't open the app.
        let logButton = UNNotificationAction(
            identifier: NotificationManager.logButtonID,
            title: "Log Period Start",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: NotificationManager.categoryID,
            actions: [logButton],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    /// Asks permission to show notifications (iOS only asks once).
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Scheduling

    /// Removes the old reminders and schedules new ones for this date.
    func scheduleReminders(predictedStart: Date, hour: Int, minute: Int) {
        clearReminders()
        scheduleHeadsUp(predictedStart: predictedStart, hour: hour, minute: minute)
        scheduleDailyReminders(predictedStart: predictedStart, hour: hour, minute: minute)
    }

    private func scheduleHeadsUp(predictedStart: Date, hour: Int, minute: Int) {
        let calendar = Calendar.current
        let fireDate = calendar.date(byAdding: .day, value: -NotificationManager.headsUpDaysBefore, to: predictedStart)!

        // Skip it if that day is already today or in the past.
        if calendar.startOfDay(for: fireDate) <= calendar.startOfDay(for: Date()) {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Period expected soon"
        content.body = "Your period is predicted to start in \(NotificationManager.headsUpDaysBefore) days, based on your logged history."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: NotificationManager.headsUpID,
            content: content,
            trigger: makeTrigger(on: fireDate, hour: hour, minute: minute)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleDailyReminders(predictedStart: Date, hour: Int, minute: Int) {
        for daysLate in 0..<NotificationManager.numberOfDailyReminders {
            let fireDate = Calendar.current.date(byAdding: .day, value: daysLate, to: predictedStart)!

            let content = UNMutableNotificationContent()
            if daysLate == 0 {
                content.title = "Your period is due today"
            } else if daysLate == 1 {
                content.title = "Your period is 1 day late"
            } else {
                content.title = "Your period is \(daysLate) days late"
            }
            content.body = "Tap Log Period Start if it's begun, or open Tide to check in."
            content.sound = .default
            content.categoryIdentifier = NotificationManager.categoryID   // adds the button

            let request = UNNotificationRequest(
                identifier: "\(NotificationManager.dailyReminderID)\(daysLate)",
                content: content,
                trigger: makeTrigger(on: fireDate, hour: hour, minute: minute)
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    /// A trigger that fires once, on `date` at hour:minute.
    private func makeTrigger(on date: Date, hour: Int, minute: Int) -> UNCalendarNotificationTrigger {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    /// Cancels every reminder Tide has scheduled.
    func clearReminders() {
        var ids: [String] = [NotificationManager.headsUpID]
        for daysLate in 0..<NotificationManager.numberOfDailyReminders {
            ids.append("\(NotificationManager.dailyReminderID)\(daysLate)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - When a notification shows up or is tapped

    /// Shows reminders as a banner even while the app is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Runs when you tap the notification or its "Log Period Start" button.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DispatchQueue.main.async {
            if response.actionIdentifier == NotificationManager.logButtonID {
                self.logPeriodFromButton()
            }
            // Tapping the notification itself just opens the app, so
            // there's nothing extra to do.
            completionHandler()
        }
    }

    private func logPeriodFromButton() {
        if let viewModel = viewModel {
            // App is open: log through the ViewModel so the screen updates.
            // It also reschedules the reminders for the next period.
            viewModel.tryToLogPeriod(on: Date())
        } else {
            // App isn't open: save straight to storage. The app picks it up
            // and reschedules reminders next time it opens.
            var data = CycleStorage.load()
            if data.isTooCloseToAnotherPeriod(Date()) {
                return   // probably a mistake, so log nothing and keep the reminders
            }
            data.addPeriodStart(on: Date())
            CycleStorage.save(data)
            clearReminders()
        }
    }
}
