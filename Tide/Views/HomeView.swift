
//
//  VIEW:

//  The "Today" tab: the cycle wheel, today's phase
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: CycleViewModel

    // Small bits of screen-only state. They don't need saving.
    @State private var bannerDismissed = false
    @State private var notYetTapped = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if viewModel.data.isPeriodDue && !bannerDismissed {
                        reminderBanner
                    }

                    if viewModel.data.periodStarts.isEmpty {
                        emptyState
                    } else {
                        phaseCard
                        quickLogCard
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(ambientBackground.ignoresSafeArea())
            .animation(.easeInOut(duration: 0.6), value: viewModel.data.currentPhase)

            // Celebration pop-up, drawn on top of everything else.
            if let milestone = viewModel.milestoneToShow {
                MilestoneCelebration(milestone: milestone, phase: viewModel.data.currentPhase) {
                    viewModel.finishMilestone()
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Tide")
                .font(.custom("Georgia", size: 28).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text(Date().formatted(date: .long, time: .omitted))
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
    }

    // MARK: - Background

    /// A soft glow of the current phase color, brightest at the top.
    private var ambientBackground: some View {
        ZStack {
            Theme.bg
            RadialGradient(
                colors: [Theme.phaseColor(viewModel.data.currentPhase).opacity(0.16), Theme.bg.opacity(0)],
                center: .top,
                startRadius: 4,
                endRadius: 420
            )
        }
    }

    // MARK: - "Your period is due" banner

    private var reminderBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.dueBannerTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Tap to log today as day one.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            Button {
                viewModel.tryToLogPeriod(on: Date())
            } label: {
                Text("Log it")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                bannerDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.system(size: 13))
            }
        }
        .padding(16)
        .background(Theme.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Nothing logged yet

    private var emptyState: some View {
        VStack(spacing: 8) {
            PandaMascot(phase: nil, size: 64)
            Text("Let's get started")
                .font(.custom("Georgia", size: 18).weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Go to the Calendar tab and tap a recent date to log your last period. The more history you add, the better Tide predicts what's next.")
                .font(.system(size: 13.5))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Phase card

    private var phaseCard: some View {
        let phase = viewModel.data.currentPhase

        return VStack(spacing: 14) {
            // Wheel in the middle, panda tucked in the top-right corner
            ZStack(alignment: .topTrailing) {
                CycleWheel(size: 150)
                    .frame(maxWidth: .infinity)

                PandaMascot(phase: phase, size: 40)
            }

            // Phase pill
            Text(viewModel.phaseTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.phaseColor(phase))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Theme.phaseSoft(phase))
                .clipShape(Capsule())

            // What your hormones are doing
            Text(phase?.hormoneNote ?? "")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)

            // Next predicted period, with the date in bold
            if viewModel.data.nextPeriodDate != nil {
                let dateText = Text(viewModel.nextPeriodText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink)

                Text("Next period predicted \(dateText)")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSoft)
            }

            // Bloating box
            VStack(spacing: 6) {
                Text("BLOATING & PUFFINESS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.phaseColor(phase))
                Text(viewModel.bloatLevelText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.phaseColor(phase))
                Text(phase?.bloatNote ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Theme.phaseSoft(phase))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(18)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Quick log

    private var quickLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Has Aunt Flo arrived? 🧳🩸")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    viewModel.tryToLogPeriod(on: Date())
                } label: {
                    Text("She's here")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    // Show "Noted" for a moment, then switch back.
                    notYetTapped = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        notYetTapped = false
                    }
                } label: {
                    Text(notYetTapped ? "Noted" : "Still in transit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(notYetTapped ? Theme.bambooGreen : Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(.easeInOut(duration: 0.2), value: notYetTapped)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Previews

#Preview("With data") {
    let viewModel = CycleViewModel()
    let today = Calendar.current.startOfDay(for: Date())
    viewModel.data.periodStarts = [
        Calendar.current.date(byAdding: .day, value: -70, to: today)!,
        Calendar.current.date(byAdding: .day, value: -42, to: today)!,
        Calendar.current.date(byAdding: .day, value: -12, to: today)!
    ]
    return HomeView()
        .environmentObject(viewModel)
}

#Preview("Empty") {
    let viewModel = CycleViewModel()
    viewModel.data.periodStarts = []
    return HomeView()
        .environmentObject(viewModel)
}
