
//
//  VIEW (component)
//  pop-up that appears when you reach a milestone (1st period logged,
//  3 cycles, 6, 12, 24) (dancing panda and falling bamboo leaves?
//

import SwiftUI

struct MilestoneCelebration: View {
    let milestone: Int
    let phase: CyclePhase?
    let onDismiss: () -> Void

    private var title: String {
        switch milestone {
        case 1: return "First period logged!"
        case 3: return "3 cycles tracked"
        case 6: return "6 cycles tracked"
        case 12: return "A full year of cycles"
        case 24: return "2 years of tracking"
        default: return "\(milestone) cycles tracked"
        }
    }

    private var subtitle: String {
        if milestone == 1 {
            return "You've started building your cycle history. The more you log, the sharper your predictions get."
        }
        return "Your predictions are getting more personal to you with every cycle you log."
    }

    var body: some View {
        ZStack {
            // Dim the screen behind the pop-up
            Color.black.opacity(0.35).ignoresSafeArea()

            ZStack {
                // 14 leaves, each starting a little after the one before
                ForEach(0..<14, id: \.self) { i in
                    FallingLeaf(delay: Double(i) * 0.06)
                }

                VStack(spacing: 14) {
                    PandaMascot(phase: phase, size: 90, celebrating: true)
                        .padding(.top, 8)

                    Text(title)
                        .font(.custom("Georgia", size: 20).weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.system(size: 13.5))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)

                    Button(action: onDismiss) {
                        Text("Yay!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Theme.bambooGreen)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .padding(28)
                .frame(maxWidth: 300)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
    }
}

/// One bamboo leaf that falls from the top, spins and fades out.
/// Each leaf picks its own random size, spot and speed when it appears.
struct FallingLeaf: View {
    let delay: Double

    @State private var x = CGFloat.random(in: 40...300)
    @State private var endY = CGFloat.random(in: 420...560)
    @State private var size = CGFloat.random(in: 16...26)
    @State private var startAngle = Double.random(in: 0...360)
    @State private var spin = Double.random(in: 180...360)
    @State private var duration = Double.random(in: 1.6...2.4)

    @State private var hasFallen = false

    var body: some View {
        Text("🎋")
            .font(.system(size: size))
            .rotationEffect(.degrees(hasFallen ? startAngle + spin : startAngle))
            .position(x: x, y: hasFallen ? endY : -20)
            .opacity(hasFallen ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    hasFallen = true
                }
            }
    }
}

#Preview {
    MilestoneCelebration(milestone: 3, phase: .follicular) { }
}
