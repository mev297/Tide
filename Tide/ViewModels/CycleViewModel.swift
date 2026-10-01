
//
//   VIEWMODEL
//  The middle layer between the Model (CycleData + CycleStorage) and the
//  Views. 
//
//  Whenever `data` changes, @Published tells every screen to redraw.
//
//  App only no widget here
//

import SwiftUI
import Combine

/// One bar in the Insights chart.
struct ChartBar: Identifiable {
    let id: Int      // cycle number: 1, 2, 3...
    let days: Int    // how long that cycle was
}

class CycleViewModel: ObservableObject {

    // MARK: - State the views watch

    /// All the cycle data. Loaded from storage when the app starts.
    @Published var data: CycleData

    /// Set when you reach a milestone, so the celebration screen appears.
    @Published var milestoneToShow: Int? = nil

    /// Shows the "That's a short gap" alert.
    @Published var showShortGapAlert = false

    /// The date waiting for you to confirm in that alert.
    var pendingDate: Date? = nil

    init() {
        data = CycleStorage.load()
        updateReminders()
    }

    // MARK: - Saving

    /// Re-reads saved data. Used when the app comes back to the screen,
    /// in case you logged a period from the widget or a notification.
    func reload() {
        data = CycleStorage.load()
        updateReminders()
    }

    /// Call after every change: saves it, then updates the reminders to
    /// match the new predicted date.
    private func saveChanges() {
        CycleStorage.save(data)
        updateReminders()
    }

    private func updateReminders() {
        if let next = data.nextPeriodDate {
            NotificationManager.shared.scheduleReminders(
                predictedStart: next,
                hour: data.reminderHour,
                minute: data.reminderMinute
            )
        } else {
            NotificationManager.shared.clearReminders()
        }
    }

    // MARK: - Logging periods

    /// Logs a period, unless it's suspiciously close to another one.
    /// In that case it asks first, using the short-gap alert.
    func tryToLogPeriod(on date: Date) {
        if data.isTooCloseToAnotherPeriod(date) {
            pendingDate = date
            showShortGapAlert = true
        } else {
            logPeriod(on: date)
        }
    }

    /// Logs a period with no questions asked.
    func logPeriod(on date: Date) {
        data.addPeriodStart(on: date)
        if let milestone = data.milestoneToCelebrate {
            milestoneToShow = milestone
        }
        saveChanges()
    }

    /// "Log anyway" in the short-gap alert.
    func confirmPendingLog() {
        if let date = pendingDate {
            logPeriod(on: date)
        }
        pendingDate = nil
    }

    /// "Cancel" in the short-gap alert.
    func cancelPendingLog() {
        pendingDate = nil
    }

    func removePeriod(on date: Date) {
        data.removePeriodStart(on: date)
        saveChanges()
    }

    /// Tapping a day on the calendar: removes the period if that day is part
    /// of one, otherwise logs a new one. Future days do nothing.
    func calendarDayTapped(_ date: Date) {
        if date > data.today {
            return
        }
        if let start = data.periodStart(containing: date) {
            removePeriod(on: start)
        } else {
            tryToLogPeriod(on: date)
        }
    }

    // MARK: - Milestones

    /// Call when the celebration screen is closed, so it doesn't show again.
    func finishMilestone() {
        if let milestone = milestoneToShow {
            data.celebratedMilestones.append(milestone)
            saveChanges()
        }
        milestoneToShow = nil
    }

    // MARK: - Settings

    /// Saves your own cycle and period lengths. Numbers outside a realistic
    /// range are pulled back into it, so a typo like 0 can't break anything.
    func setCustomLengths(cycle: Int?, period: Int?) {
        data.customCycleLength = keep(cycle, between: 15, and: 60)
        data.customPeriodLength = keep(period, between: 1, and: 10)
        saveChanges()
    }

    /// Goes back to working the lengths out from your logged history.
    func useAutomaticLengths() {
        data.customCycleLength = nil
        data.customPeriodLength = nil
        saveChanges()
    }

    func setReminderTime(hour: Int, minute: Int) {
        data.reminderHour = hour
        data.reminderMinute = minute
        saveChanges()
    }

    private func keep(_ value: Int?, between low: Int, and high: Int) -> Int? {
        if let value = value {
            if value < low {
                return low
            }
            if value > high {
                return high
            }
            return value
        }
        return nil
    }

    // MARK: - Text for the screens

    var phaseTitle: String {
        if let phase = data.currentPhase {
            return "\(phase.rawValue) phase"
        }
        return "— phase"
    }

    /// Bloating is always "High" in the last few days before a period.
    var bloatLevelText: String {
        if data.isLateLuteal {
            return "High"
        }
        return data.currentPhase?.bloatLevel ?? ""
    }

    /// Energy is always "Low" in the last few days before a period.
    var energyLevelText: String {
        if data.isLateLuteal {
            return "Low"
        }
        return data.currentPhase?.energyLevel ?? ""
    }

    /// Like "Oct 31".
    var nextPeriodText: String {
        if let next = data.nextPeriodDate {
            return next.formatted(.dateTime.month(.abbreviated).day())
        }
        return ""
    }

    /// The title of the banner on the Today screen.
    var dueBannerTitle: String {
        let late = data.daysLate
        if late == 0 {
            return "Your period is due today"
        }
        if late == 1 {
            return "Your period is 1 day late"
        }
        return "Your period is \(late) days late"
    }

    var shortGapMessage: String {
        if let date = pendingDate, let closest = data.closestPeriodStart(to: date) {
            let gap = abs(data.daysBetween(closest, date))
            let dayWord = gap == 1 ? "day" : "days"
            let start = Calendar.current.isDateInToday(date) ? "Today is" : "This date is"
            let closestText = closest.formatted(date: .long, time: .omitted)
            return "\(start) only \(gap) \(dayWord) from a period you logged on \(closestText). A typical cycle runs at least \(CycleData.shortestRealisticCycle) days, so this might be an accidental tap. Log it anyway?"
        }
        return ""
    }

    // MARK: - Cycle wheel

    /// How far around the wheel today's dot sits, from 0 to just under 1.
    /// If your period is late, the dot waits at the end of the wheel.
    var todayPositionOnWheel: Double {
        if let days = data.daysSinceLastPeriod {
            let lastDay = data.cycleLength - 1
            let position = min(days, lastDay)
            return Double(position) / Double(data.cycleLength)
        }
        return 0
    }

    // MARK: - Insights chart

    var chartBars: [ChartBar] {
        var bars: [ChartBar] = []
        let lengths = data.recentCycleLengths
        for i in 0..<lengths.count {
            bars.append(ChartBar(id: i + 1, days: lengths[i]))
        }
        return bars
    }
}
