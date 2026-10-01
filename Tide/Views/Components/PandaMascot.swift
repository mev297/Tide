
//
//  VIEW - component
//  Tide's mascot is a panda. it wiggles and bounces and is super cute
//
//  Shared with the widget!!!!
//

import SwiftUI

struct PandaMascot: View {
    let phase: CyclePhase?
    var size: CGFloat = 90
    var celebrating: Bool = false

    // Used for the animations.
    @State private var bob: CGFloat = 0      // up/down movement
    @State private var wiggle: Double = 0    // tilt left/right

    /// The little emoji next to the panda for each phase.
    private var moodEmoji: String? {
        switch phase {
        case .menstrual: return "💤"
        case .follicular: return "🌱"
        case .ovulation: return "✨"
        case .luteal: return "🎋"
        case .none: return nil
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text("🐼")
                .font(.system(size: size))

            if let emoji = moodEmoji {
                Text(emoji)
                    .font(.system(size: size * 0.34))
                    .offset(x: size * 0.12, y: -size * 0.06)
            }
        }
        .rotationEffect(.degrees(wiggle))
        .offset(y: bob)
        .onAppear {
            if celebrating {
                startCelebration()
            } else {
                startIdleMotion()
            }
        }
    }

    /// A slow, gentle float up and down, forever.
    private func startIdleMotion() {
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            bob = -4
        }
    }

    /// Fast bouncing and wiggling for the milestone pop-up.
    private func startCelebration() {
        withAnimation(.easeInOut(duration: 0.22).repeatForever(autoreverses: true)) {
            wiggle = 10
        }
        withAnimation(.easeInOut(duration: 0.26).repeatForever(autoreverses: true)) {
            bob = -14
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        PandaMascot(phase: .menstrual, size: 60)
        PandaMascot(phase: .ovulation, size: 60)
        PandaMascot(phase: nil, size: 60, celebrating: true)
    }
}
