
//
//  MODEL:

//  Everything Tide knows about your cycle
//   +  all the math worked out from them:
//  1. what day of the cycle it is
//  2. which phase you're in
//  3. when the next period is due.
//
//  plain struct. no UI code, and it doesn't save or load
//
//
//  Also shared with the widget!!!!!
//

import Foundation

struct CycleData {

    // MARK: - Stored data

    /// Every period start you've logged, oldest first, each set to midnight.
    var periodStarts: [Date] = []

    /// Your own numbers from Settings. nil means "work it out automatically".
    var customCycleLength: Int? = nil
    var customPeriodLength: Int? = nil

    /// When the daily reminder fires. Defaults to 9:00 AM.
    var reminderHour: Int = 9
    var reminderMinute: Int = 0

    /// Milestones that have already had their celebration screen.
    var celebratedMilestones: [Int] = []

    // MARK: - Rules

    static let defaultCycleLength = 28
    static let defaultPeriodLength = 5

    /// Two periods closer than this are probably an accidental tap.
    static let shortestRealisticCycle = 18

    /// Number of logged periods that trigger a celebration.
    static let milestones = [1, 3, 6, 12, 24]

    // MARK: - Date helpers

    /// Today, at midnight.
    var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    /// Whole days from one date to another. Negative if `end` is earlier.
    func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    // MARK: - Adding and removing periods

    func hasPeriodStart(on date: Date) -> Bool {
        for start in periodStarts {
            if Calendar.current.isDate(start, inSameDayAs: date) {
                return true
            }
        }
        return false
    }

    mutating func addPeriodStart(on date: Date) {
        if hasPeriodStart(on: date) {
            return
        }
        periodStarts.append(Calendar.current.startOfDay(for: date))
        periodStarts.sort()
    }

    mutating func removePeriodStart(on date: Date) {
        periodStarts.removeAll { start in
            Calendar.current.isDate(start, inSameDayAs: date)
        }
    }

    // MARK: - Lengths

    /// The gap in days between each pair of logged periods.
    var cycleLengths: [Int] {
        var lengths: [Int] = []
        if periodStarts.count < 2 {
            return lengths
        }
        for i in 1..<periodStarts.count {
            lengths.append(daysBetween(periodStarts[i - 1], periodStarts[i]))
        }
        return lengths
    }

    /// Your custom number if you set one, otherwise the average of your
    /// last 6 cycles, otherwise 28.
    var cycleLength: Int {
        if let custom = customCycleLength, custom > 0 {
            return custom
        }

        let recent = cycleLengths.suffix(6)
        if recent.isEmpty {
            return CycleData.defaultCycleLength
        }

        var total = 0
        for length in recent {
            total += length
        }
        let average = Double(total) / Double(recent.count)
        return Int(average.rounded())
    }

    var periodLength: Int {
        if let custom = customPeriodLength, custom > 0 {
            return custom
        }
        return CycleData.defaultPeriodLength
    }

    /// Ovulation usually happens about 14 days before the next period.
    var ovulationDay: Int {
        cycleLength - 14
    }

    // MARK: - Where you are right now

    var lastPeriodStart: Date? {
        periodStarts.last
    }

    var nextPeriodDate: Date? {
        if let last = lastPeriodStart {
            return Calendar.current.date(byAdding: .day, value: cycleLength, to: last)
        }
        return nil
    }

    /// 0 on the day your last period started.
    var daysSinceLastPeriod: Int? {
        if let last = lastPeriodStart {
            return daysBetween(last, today)
        }
        return nil
    }

    /// The "Day 12" number shown on screen. Starts at 1, and keeps counting
    /// past your usual cycle length if your period is late.
    var dayNumber: Int? {
        if let days = daysSinceLastPeriod {
            return days + 1
        }
        return nil
    }

    var currentPhase: CyclePhase? {
        phase(on: today)
    }

    /// The last 5 days before a period, when bloating peaks and energy dips.
    var isLateLuteal: Bool {
        if currentPhase != .luteal {
            return false
        }
        if let days = daysSinceLastPeriod {
            return days >= cycleLength - 5
        }
        return false
    }

    /// True once the predicted date has arrived.
    var isPeriodDue: Bool {
        if let next = nextPeriodDate {
            return next <= today
        }
        return false
    }

    var daysLate: Int {
        if let next = nextPeriodDate {
            return max(0, daysBetween(next, today))
        }
        return 0
    }

    // MARK: - Phase for any date (used by calendar)

    func phase(on date: Date) -> CyclePhase? {
        if periodStarts.isEmpty {
            return nil
        }
        let day = Calendar.current.startOfDay(for: date)

        // 1. Find the most recent logged period on or before this date.
        //    (Dates before your first log just use the first one.)
        var anchor = periodStarts[0]
        for start in periodStarts {
            if start <= day {
                anchor = start
            }
        }
        var position = daysBetween(anchor, day)

        // 2. If your period is late, you're still in the luteal phase
        //    until you log the new one.
        if anchor == lastPeriodStart && position >= cycleLength && day <= today {
            return .luteal
        }

        // 3. Otherwise repeat the pattern every cycleLength days, so the
        //    calendar can show future (and earlier) months.
        while position < 0 {
            position += cycleLength
        }
        position = position % cycleLength

        return phaseForDay(position)
    }

    /// Which phase a given day of the cycle falls in (day 0 = period starts).
    private func phaseForDay(_ day: Int) -> CyclePhase {
        if day < periodLength {
            return .menstrual
        }
        if day < ovulationDay - 1 {
            return .follicular
        }
        if day <= ovulationDay + 1 {
            return .ovulation
        }
        return .luteal
    }

    // MARK: - Calendar helpers

    /// If `date` falls inside a logged period, returns the day that period
    /// started. Otherwise nil.
    func periodStart(containing date: Date) -> Date? {
        for start in periodStarts {
            let day = daysBetween(start, date)
            if day >= 0 && day < periodLength {
                return start
            }
        }
        return nil
    }

    /// True for the days of the next predicted period.
    func isInPredictedPeriod(_ date: Date) -> Bool {
        if let next = nextPeriodDate {
            let day = daysBetween(next, date)
            return day >= 0 && day < periodLength
        }
        return false
    }

    // MARK: - Short-gap check

    /// The logged period start closest to `date`, before or after it.
    func closestPeriodStart(to date: Date) -> Date? {
        var closest: Date? = nil
        var smallestGap = Int.max
        for start in periodStarts {
            let gap = abs(daysBetween(start, date))
            if gap < smallestGap {
                smallestGap = gap
                closest = start
            }
        }
        return closest
    }

    /// True if logging date would make an unrealistically short cycle .... so less than a week or two
    /// which usually means an accidental tap.
    func isTooCloseToAnotherPeriod(_ date: Date) -> Bool {
        if let closest = closestPeriodStart(to: date) {
            return abs(daysBetween(closest, date)) < CycleData.shortestRealisticCycle
        }
        return false
    }

    // MARK: - Insights

    var shortestCycle: Int? {
        cycleLengths.min()
    }

    var longestCycle: Int? {
        cycleLengths.max()
    }

    /// Up to the last 12 cycle lengths, oldest first, for the chart.
    var recentCycleLengths: [Int] {
        Array(cycleLengths.suffix(12))
    }

    // MARK: - Milestones

    /// A milestone you've just reached that hasn't been celebrated yet. try to do milestone for every 3 cycles loaded mayb ?
    var milestoneToCelebrate: Int? {
        let count = periodStarts.count
        if CycleData.milestones.contains(count) && !celebratedMilestones.contains(count) {
            return count
        }
        return nil
    }
}
