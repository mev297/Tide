//
//  VIEW (component)
//  The colored ring on the Today screen. Each colored arc is one phase ( decide the colour !!!!) 
//  the dot shows where today is, and the middle shows the day number.
//

import SwiftUI

struct CycleWheel: View {
    @EnvironmentObject var viewModel: CycleViewModel
    let size: CGFloat

    var body: some View {
        let data = viewModel.data

        // Which day each phase ends on (day 0 = period starts).
        let periodEnd = data.periodLength
        let follicularEnd = max(data.ovulationDay - 1, periodEnd + 1)
        let ovulationEnd = max(data.ovulationDay + 2, follicularEnd + 1)
        let cycleEnd = data.cycleLength

        ZStack {
            // The four phase arcs
            arc(from: 0, to: periodEnd, color: Theme.menstrual)
            arc(from: periodEnd, to: follicularEnd, color: Theme.follicular)
            arc(from: follicularEnd, to: ovulationEnd, color: Theme.ovulation)
            arc(from: ovulationEnd, to: cycleEnd, color: Theme.luteal)

            // Today's dot: start it at the top of the ring, then spin it
            // around the middle to the right spot.
            Circle()
                .fill(Theme.ink)
                .frame(width: size * 0.06, height: size * 0.06)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(y: -size * 0.37)
                .rotationEffect(.degrees(viewModel.todayPositionOnWheel * 360))

            // Day number in the middle
            VStack(spacing: 2) {
                Text("Day")
                    .font(.system(size: size * 0.09))
                    .foregroundStyle(Theme.inkSoft)
                Text("\(data.dayNumber ?? 1)")
                    .font(.custom("Georgia", size: size * 0.19).weight(.semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .frame(width: size, height: size)
    }

    /// One colored piece of the ring, from one cycle day to another.
    private func arc(from startDay: Int, to endDay: Int, color: Color) -> some View {
        let total = Double(viewModel.data.cycleLength)
        let gap = 0.006   // tiny space between the colors

        // Turn days into "how far around the circle" (0 = top, 1 = all the way).
        var start = Double(startDay) / total + gap
        var end = Double(endDay) / total - gap

        // Keep everything inside the circle.
        if start > 1 {
            start = 1
        }
        if end > 1 {
            end = 1
        }
        if end < start {
            end = start
        }

        return Circle()
            .trim(from: start, to: end)
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.14, lineCap: .round))
            .rotationEffect(.degrees(-90))   // so 0 starts at the top, not the right
    }
}

#Preview {
    let viewModel = CycleViewModel()
    let today = Calendar.current.startOfDay(for: Date())
    viewModel.data.periodStarts = [
        Calendar.current.date(byAdding: .day, value: -12, to: today)!
    ]
    return CycleWheel(size: 150)
        .environmentObject(viewModel)
}
