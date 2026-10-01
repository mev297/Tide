
//
//  MODEL:
//  Saves and loads CycleData. Everything is stored in a shared App Group,
//  so the widget can read the same data as the app.
//
//
//  Shared with the widget !!!!
//
//

import Foundation
import WidgetKit

struct CycleStorage {

    static let appGroupID = "group.com.merlyn.tide"

    // The names each value is saved under.
    static let periodStartsKey = "tide.cycleStarts"
    static let customCycleLengthKey = "tide.overrideCycleLength"
    static let customPeriodLengthKey = "tide.overridePeriodLength"
    static let celebratedMilestonesKey = "tide.celebratedMilestones"
    static let reminderHourKey = "tide.reminderHour"
    static let reminderMinuteKey = "tide.reminderMinute"

    /// The shared storage. Falls back to the app's normal storage if the
    /// App Group isn't set up yet, so the app still runs.
    static var defaults: UserDefaults {
        if let shared = UserDefaults(suiteName: appGroupID) {
            return shared
        }
        return UserDefaults.standard
    }

    // MARK: - Load

    static func load() -> CycleData {
        var data = CycleData()

        // Period dates are saved as JSON.
        if let saved = defaults.data(forKey: periodStartsKey) {
            if let dates = try? JSONDecoder().decode([Date].self, from: saved) {
                data.periodStarts = dates.sorted()
            }
        }

        // Custom lengths only exist if you set them in Settings.
        if defaults.object(forKey: customCycleLengthKey) != nil {
            data.customCycleLength = defaults.integer(forKey: customCycleLengthKey)
        }
        if defaults.object(forKey: customPeriodLengthKey) != nil {
            data.customPeriodLength = defaults.integer(forKey: customPeriodLengthKey)
        }

        if let milestones = defaults.array(forKey: celebratedMilestonesKey) as? [Int] {
            data.celebratedMilestones = milestones
        }

        if defaults.object(forKey: reminderHourKey) != nil {
            data.reminderHour = defaults.integer(forKey: reminderHourKey)
        }
        if defaults.object(forKey: reminderMinuteKey) != nil {
            data.reminderMinute = defaults.integer(forKey: reminderMinuteKey)
        }

        return data
    }

    // MARK: - Save

    static func save(_ data: CycleData) {
        if let encoded = try? JSONEncoder().encode(data.periodStarts) {
            defaults.set(encoded, forKey: periodStartsKey)
        }

        // Save a custom length if there is one, otherwise remove it so
        // the app goes back to working it out automatically.
        if let custom = data.customCycleLength {
            defaults.set(custom, forKey: customCycleLengthKey)
        } else {
            defaults.removeObject(forKey: customCycleLengthKey)
        }
        if let custom = data.customPeriodLength {
            defaults.set(custom, forKey: customPeriodLengthKey)
        } else {
            defaults.removeObject(forKey: customPeriodLengthKey)
        }

        defaults.set(data.celebratedMilestones, forKey: celebratedMilestonesKey)
        defaults.set(data.reminderHour, forKey: reminderHourKey)
        defaults.set(data.reminderMinute, forKey: reminderMinuteKey)

        // Tell the widget the data changed so it redraws right away,
        // instead of waiting until midnight.
        WidgetCenter.shared.reloadTimelines(ofKind: "TideWidget")
    }
}
