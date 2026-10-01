
//
//  VIEW
//  The "Calendar" tab: a month grid colored by phase, where you tap a day
//  to log or remove a period, plus a list of every period you've logged.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: CycleViewModel

    /// The month being shown. Starts on this month.
    @State private var visibleMonth = Date()

    private let weekdayLetters = ["S", "M", "T", "W", "T", "F", "S"]

    /// 7 equal columns, one per day of the week.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                calendarCard
                historyCard
            }
            .padding(18)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    // MARK: - Building the month

    /// Every day of the visible month, with empty (nil) boxes at the start
    /// so the 1st lines up under the right weekday.
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        var days: [Date?] = []

        if let month = calendar.dateInterval(of: .month, for: visibleMonth) {
            // 1 = Sunday, 2 = Monday... so a month starting on Wednesday (4)
            // gets 3 empty boxes first.
            let weekdayOfFirst = calendar.component(.weekday, from: month.start)
            for _ in 1..<weekdayOfFirst {
                days.append(nil)
            }

            var day = month.start
            while day < month.end {
                days.append(day)
                day = calendar.date(byAdding: .day, value: 1, to: day)!
            }
        }
        return days
    }

    private func changeMonth(by amount: Int) {
        visibleMonth = Calendar.current.date(byAdding: .month, value: amount, to: visibleMonth)!
    }

    // MARK: - Calendar card

    private var calendarCard: some View {
        VStack(spacing: 12) {
            // Month name with arrows
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left").foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.custom("Georgia", size: 15).weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                }
            }

            // S M T W T F S
            HStack {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdayLetters[i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                }
            }

            // The days
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<daysInMonth.count, id: \.self) { i in
                    if let date = daysInMonth[i] {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }

            legend

            Text("Tap a past date to log it. Tap a logged date again to remove it.")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 2)
        }
        .padding(18)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - One day

    private func dayCell(_ date: Date) -> some View {
        let data = viewModel.data
        let isFuture = date > data.today
        let isToday = Calendar.current.isDateInToday(date)
        let isLogged = data.periodStart(containing: date) != nil
        let isPredicted = data.isInPredictedPeriod(date)

        // Background: dark red for logged periods, otherwise the phase color.
        var background = Theme.phaseSoft(data.phase(on: date))
        var textColor = Theme.ink
        if isFuture {
            textColor = Theme.ink.opacity(0.3)
        }
        if isLogged {
            background = Theme.menstrual
            textColor = .white
        }

        // Border: solid for today, dashed for a predicted period.
        var borderColor = Color.clear
        var borderWidth: CGFloat = 1.5
        var dash: [CGFloat] = []
        if isToday {
            borderColor = Theme.primary
            borderWidth = 2
        } else if isPredicted {
            borderColor = Theme.menstrual
            dash = [3, 3]
        }

        return Button {
            viewModel.calendarDayTapped(date)
        } label: {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 12.5, weight: isToday ? .bold : .regular))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, style: StrokeStyle(lineWidth: borderWidth, dash: dash))
                )
        }
        .disabled(isFuture)
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 14) {
                legendDot(Theme.menstrual, "Logged")
                legendDashed("Predicted")
            }
            HStack(spacing: 14) {
                legendDot(Theme.menstrualSoft, "Menstrual")
                legendDot(Theme.follicularSoft, "Follicular")
            }
            HStack(spacing: 14) {
                legendDot(Theme.ovulationSoft, "Ovulation")
                legendDot(Theme.lutealSoft, "Luteal")
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(Theme.inkSoft)
        .padding(.top, 4)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
        }
    }

    private func legendDashed(_ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.menstrual, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                .frame(width: 10, height: 10)
            Text(label)
        }
    }

    // MARK: - History card

    private var historyCard: some View {
        let starts = viewModel.data.periodStarts

        return VStack(alignment: .leading, spacing: 10) {
            Text("Period history")
                .font(.custom("Georgia", size: 15).weight(.semibold))
                .foregroundStyle(Theme.ink)

            if starts.isEmpty {
                Text("No periods logged yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                // Newest first
                ForEach(Array(starts.indices.reversed()), id: \.self) { i in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(starts[i].formatted(date: .long, time: .omitted))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.ink)

                            // The very first period has no cycle before it.
                            if i > 0 {
                                Text("\(viewModel.data.cycleLengths[i - 1])-day cycle")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        Spacer()
                        Button {
                            viewModel.removePeriod(on: starts[i])
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Theme.inkSoft)
                                .font(.system(size: 13))
                        }
                    }
                    .padding(10)
                    .background(Theme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(18)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    let viewModel = CycleViewModel()
    let today = Calendar.current.startOfDay(for: Date())
    viewModel.data.periodStarts = [
        Calendar.current.date(byAdding: .day, value: -70, to: today)!,
        Calendar.current.date(byAdding: .day, value: -42, to: today)!,
        Calendar.current.date(byAdding: .day, value: -12, to: today)!
    ]
    return CalendarView()
        .environmentObject(viewModel)
}
