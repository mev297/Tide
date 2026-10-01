
//
//  VIEW
//  The "Insights" tab:  averages, a chart of past cycle lengths, and a
//  guide to what usually happens in each phase.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var viewModel: CycleViewModel

    /// Which phase in the guide is opened up. nil = all closed.
    @State private var expandedPhase: CyclePhase? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                // You need at least two periods to have one full cycle.
                if viewModel.data.cycleLengths.isEmpty {
                    emptyState
                } else {
                    statsGrid
                    trendChart
                }

                phaseGuide
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Insights")
                .font(.custom("Georgia", size: 26).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Your averages and trends, based on what you've logged.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
    }

    // MARK: - Not enough data yet

    private var emptyState: some View {
        VStack(spacing: 10) {
            PandaMascot(phase: nil, size: 64)
            Text("Not enough data yet")
                .font(.custom("Georgia", size: 18).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Log at least two periods on the Calendar tab to start seeing your averages and trends here.")
                .font(.system(size: 13.5))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Stats

    private var statsGrid: some View {
        let data = viewModel.data
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 12) {
            statCard(title: "Average cycle", value: "\(data.cycleLength)d")
            statCard(title: "Average period", value: "\(data.periodLength)d")
            if let shortest = data.shortestCycle {
                statCard(title: "Shortest cycle", value: "\(shortest)d")
            }
            if let longest = data.longestCycle {
                statCard(title: "Longest cycle", value: "\(longest)d")
            }
            statCard(title: "Total logged", value: "\(data.periodStarts.count)")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
            Text(value)
                .font(.custom("Georgia", size: 26).weight(.semibold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Chart

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cycle length over time")
                .font(.custom("Georgia", size: 15).weight(.semibold))
                .foregroundStyle(Theme.ink)

            Chart(viewModel.chartBars) { bar in
                BarMark(
                    x: .value("Cycle", bar.id),
                    y: .value("Days", bar.days)
                )
                .foregroundStyle(Theme.bambooGreen)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxisLabel("days")
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Phase guide

    private var phaseGuide: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Phase guide")
                .font(.custom("Georgia", size: 18).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("What tends to happen in your body during each phase.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.inkSoft)

            VStack(spacing: 10) {
                phaseRow(.menstrual)
                phaseRow(.follicular)
                phaseRow(.ovulation)
                phaseRow(.luteal)
            }
        }
    }

    /// One phase in the guide. Tap it to open or close it.
    private func phaseRow(_ phase: CyclePhase) -> some View {
        let isExpanded = (expandedPhase == phase)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedPhase = nil
                    } else {
                        expandedPhase = phase
                    }
                }
            } label: {
                HStack {
                    Text(phase.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.phaseColor(phase))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    guideLine(label: "Hormones", text: phase.hormoneNote)
                    guideLine(label: "Energy", text: phase.energyNote)
                    guideLine(label: "Appetite", text: phase.appetiteNote)
                    guideLine(label: "Skin", text: phase.skinNote)
                    guideLine(label: "Mood", text: phase.moodNote)
                    guideLine(label: "Weight & bloating", text: phase.weightNote)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func guideLine(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    let viewModel = CycleViewModel()
    let today = Calendar.current.startOfDay(for: Date())
    viewModel.data.periodStarts = [
        Calendar.current.date(byAdding: .day, value: -90, to: today)!,
        Calendar.current.date(byAdding: .day, value: -61, to: today)!,
        Calendar.current.date(byAdding: .day, value: -33, to: today)!,
        Calendar.current.date(byAdding: .day, value: -4, to: today)!
    ]
    return InsightsView()
        .environmentObject(viewModel)
}
