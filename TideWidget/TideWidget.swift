
//  Home screen and lock screen widgets.
//
//  The widget runs separately from the app, so it can't use the app's
//  ViewModel. It reads the Models directly (CycleStorage and
//  CycleData)
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - "Log period" button

/// What happens when you tap "Log period" on the widget.
struct LogPeriodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Period Start"
    static var description = IntentDescription("Logs today as the start of a new period in Tide.")

    func perform() async throws -> some IntentResult {
        var data = CycleStorage.load()

        // Skip it if it's suspiciously close to another period (probably
        // an accidental tap). Saving also refreshes the widget.
        if !data.isTooCloseToAnotherPeriod(Date()) {
            data.addPeriodStart(on: Date())
            CycleStorage.save(data)
        }
        return .result()
    }
}

// MARK: - What the widget shows

/// A snapshot of everything the widget needs to draw itself.
struct TideEntry: TimelineEntry {
    let date: Date
    let phase: CyclePhase?
    let dayNumber: Int
    let cycleLength: Int
    let nextPeriodDate: Date?
    let bloatLevel: String
    let energyLevel: String
    let hasData: Bool

    /// Fake data for the widget gallery and previews.
    static let example = TideEntry(
        date: Date(),
        phase: .follicular,
        dayNumber: 10,
        cycleLength: 28,
        nextPeriodDate: Date(),
        bloatLevel: "Low",
        energyLevel: "Rising",
        hasData: true
    )
}

// MARK: - When the widget updates

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> TideEntry {
        TideEntry.example
    }

    func getSnapshot(in context: Context, completion: @escaping (TideEntry) -> Void) {
        completion(makeEntry())
    }

    /// Draws the widget now, then asks iOS to redraw it at midnight
    /// (when the day number changes).
    func getTimeline(in context: Context, completion: @escaping (Timeline<TideEntry>) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let timeline = Timeline(entries: [makeEntry()], policy: .after(midnight))
        completion(timeline)
    }

    /// Loads the saved data and turns it into a TideEntry.
    private func makeEntry() -> TideEntry {
        let data = CycleStorage.load()

        // Same rule as the app: bloating is "High" and energy "Low" in the
        // last few days before a period.
        var bloat = data.currentPhase?.bloatLevel ?? "—"
        var energy = data.currentPhase?.energyLevel ?? "—"
        if data.isLateLuteal {
            bloat = "High"
            energy = "Low"
        }

        return TideEntry(
            date: Date(),
            phase: data.currentPhase,
            dayNumber: data.dayNumber ?? 1,
            cycleLength: data.cycleLength,
            nextPeriodDate: data.nextPeriodDate,
            bloatLevel: bloat,
            energyLevel: energy,
            hasData: !data.periodStarts.isEmpty
        )
    }
}

// MARK: - How the widget looks

struct TideWidgetEntryView: View {
    var entry: TideEntry

    /// Which size the widget is (small, medium, lock screen...).
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if !entry.hasData {
                emptyView
            } else if family == .systemSmall {
                smallView
            } else if family == .accessoryCircular {
                circularView
            } else if family == .accessoryRectangular {
                rectangularView
            } else if family == .accessoryInline {
                inlineView
            } else {
                mediumView
            }
        }
        .containerBackground(backgroundColor, for: .widget)
    }

    /// Lock screen widgets ignore custom colors, so they get a clear background.
    private var backgroundColor: Color {
        if family == .systemSmall || family == .systemMedium {
            return Theme.bg
        }
        return .clear
    }

    // MARK: Nothing logged yet

    @ViewBuilder
    private var emptyView: some View {
        if family == .accessoryCircular {
            Image(systemName: "drop")
        } else if family == .accessoryRectangular {
            Text("Tide: no periods logged yet")
                .font(.system(size: 12))
        } else if family == .accessoryInline {
            Text("Tide: nothing logged yet")
        } else {
            VStack(spacing: 6) {
                PandaMascot(phase: nil, size: 36)
                Text("No periods logged yet")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    // MARK: Lock screen

    /// A ring that fills up as the cycle goes on. Tap it to log a period.
    private var circularView: some View {
        Button(intent: LogPeriodIntent()) {
            Gauge(value: Double(min(entry.dayNumber, entry.cycleLength)), in: 0...Double(entry.cycleLength)) {
                Text("Day")
            } currentValueLabel: {
                Text("\(entry.dayNumber)")
            }
            .gaugeStyle(.accessoryCircularCapacity)
        }
        .buttonStyle(.plain)
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.phase?.rawValue ?? "Tide")
                .font(.system(size: 13, weight: .semibold))
            Text("Day \(entry.dayNumber) of ~\(entry.cycleLength)")
                .font(.system(size: 12))
            Button(intent: LogPeriodIntent()) {
                Text("Log period")
                    .font(.system(size: 11, weight: .semibold))
            }
        }
    }

    private var inlineView: some View {
        Text("Tide: Day \(entry.dayNumber), \(entry.phase?.rawValue ?? "—")")
    }

    // MARK: Home screen

    private var smallView: some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                PandaMascot(phase: entry.phase, size: 28)
            }
            Text(entry.phase?.rawValue ?? "—")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.phaseColor(entry.phase))
            Text("Day \(entry.dayNumber)")
                .font(.custom("Georgia", size: 22).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 2)
            Button(intent: LogPeriodIntent()) {
                Text("Log period")
                    .font(.system(size: 11, weight: .semibold))
            }
            .tint(Theme.primary)
        }
        .padding(12)
    }

    private var mediumView: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.phase?.rawValue ?? "—")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.phaseColor(entry.phase))
                Text("Day \(entry.dayNumber) of ~\(entry.cycleLength)")
                    .font(.custom("Georgia", size: 20).weight(.semibold))
                    .foregroundStyle(Theme.ink)
                if let next = entry.nextPeriodDate {
                    Text("Next period: \(next.formatted(date: .long, time: .omitted))")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkSoft)
                }
                Text("Bloating: \(entry.bloatLevel)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkSoft)
                Text("Energy: \(entry.energyLevel)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            VStack(spacing: 8) {
                PandaMascot(phase: entry.phase, size: 44)
                Button(intent: LogPeriodIntent()) {
                    Text("Log period")
                        .font(.system(size: 11, weight: .semibold))
                }
                .tint(Theme.primary)
            }
        }
        .padding(14)
    }
}

// MARK: - Widget setup

struct TideWidget: Widget {
    let kind = "TideWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TideWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tide")
        .description("See your current cycle phase and log today's period.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct TideWidgetBundle: WidgetBundle {
    var body: some Widget {
        TideWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    TideWidget()
} timeline: {
    TideEntry.example
}

#Preview("Medium", as: .systemMedium) {
    TideWidget()
} timeline: {
    TideEntry.example
}
