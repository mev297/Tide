import SwiftUI

enum Theme {
    static let bg = Color(red: 0.984, green: 0.961, blue: 0.945)      // #FBF5F1
    static let card = Color.white
    static let ink = Color(red: 0.169, green: 0.129, blue: 0.188)     // #2B2130
    static let inkSoft = Color(red: 0.478, green: 0.431, blue: 0.510) // #7A6E82
    static let primary = Color(red: 0.545, green: 0.227, blue: 0.384) // #8B3A62
    static let primarySoft = Color(red: 0.957, green: 0.882, blue: 0.918) // #F4E1EA
    static let line = Color(red: 0.929, green: 0.886, blue: 0.902)    // #EDE2E6

    static let menstrual = Color(red: 0.722, green: 0.361, blue: 0.420)      // #B85C6B
    static let menstrualSoft = Color(red: 0.961, green: 0.871, blue: 0.882)  // #F5DEE1
    static let follicular = Color(red: 0.788, green: 0.604, blue: 0.227)     // #C99A3A
    static let follicularSoft = Color(red: 0.961, green: 0.918, blue: 0.827) // #F5EAD3
    static let ovulation = Color(red: 0.373, green: 0.561, blue: 0.463)      // #5F8F76
    static let ovulationSoft = Color(red: 0.863, green: 0.922, blue: 0.882)  // #DCEBE1
    static let luteal = Color(red: 0.482, green: 0.427, blue: 0.576)         // #7B6D93
    static let lutealSoft = Color(red: 0.902, green: 0.882, blue: 0.937)     // #E6E1EF

    // Panda mascot palette
    static let pandaBlack = Color(red: 0.157, green: 0.161, blue: 0.176)     // #282929
    static let pandaWhite = Color.white
    static let bambooGreen = Color(red: 0.376, green: 0.541, blue: 0.376)    // #608A60
    static let bambooLight = Color(red: 0.678, green: 0.784, blue: 0.588)    // #ADC896
    static let blush = Color(red: 0.945, green: 0.671, blue: 0.694)          // #F1ABB1

    static func phaseColor(_ phase: CyclePhase?) -> Color {
        switch phase {
        case .menstrual: return menstrual
        case .follicular: return follicular
        case .ovulation: return ovulation
        case .luteal: return luteal
        case .none: return inkSoft
        }
    }

    static func phaseSoft(_ phase: CyclePhase?) -> Color {
        switch phase {
        case .menstrual: return menstrualSoft
        case .follicular: return follicularSoft
        case .ovulation: return ovulationSoft
        case .luteal: return lutealSoft
        case .none: return line
        }
    }
}
