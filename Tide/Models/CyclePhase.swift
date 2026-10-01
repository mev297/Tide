
//
//  MODEL :
//  The four phases of a menstrual cycle, plus the short notes Tide shows
//  for each one.
//  
//
//  Shared with the widget!!!!
//  reminder to tick both "Tide" and "TideWidgetExtension" beofre trying ot make it work
//
//

import Foundation

enum CyclePhase: String {
    case menstrual = "Menstrual"
    case follicular = "Follicular"
    case ovulation = "Ovulation"
    case luteal = "Luteal"

    var hormoneNote: String {
        switch self {
        case .menstrual:
            return "Estrogen and progesterone are both at their lowest. This drop is what triggers your period to start."
        case .follicular:
            return "Estrogen starts climbing steadily as your body prepares an egg. Energy tends to rise with it."
        case .ovulation:
            return "Estrogen peaks, then a surge of LH triggers the release of an egg."
        case .luteal:
            return "Progesterone rises then drops sharply in the last few days if pregnancy doesn't occur."
        }
    }

    var bloatLevel: String {
        switch self {
        case .menstrual: return "Low, easing"
        case .follicular: return "Low"
        case .ovulation: return "Mild"
        case .luteal: return "Rising to high"
        }
    }

    var energyLevel: String {
        switch self {
        case .menstrual: return "Low"
        case .follicular: return "Rising"
        case .ovulation: return "High"
        case .luteal: return "Tapering"
        }
    }

    var bloatNote: String {
        switch self {
        case .menstrual:
            return "Water retention from the days before usually starts to let up now."
        case .follicular:
            return "Generally the calmest stretch for bloating and puffiness."
        case .ovulation:
            return "A small, brief uptick in bloating around release is common for some people."
        case .luteal:
            return "This is when water retention, puffiness, and that heavier feeling are most likely, especially the last 3-5 days."
        }
    }

    var energyNote: String {
        switch self {
        case .menstrual:
            return "Energy is often lowest here, especially on the first day or two. Resting is reasonable, not lazy."
        case .follicular:
            return "Energy typically climbs steadily through this phase as estrogen rises."
        case .ovulation:
            return "This is usually the highest-energy window in the cycle."
        case .luteal:
            return "Energy gradually tapers off, more noticeably in the final days before your period."
        }
    }

    var appetiteNote: String {
        switch self {
        case .menstrual:
            return "Appetite is usually back to baseline, though cravings from the days before may linger briefly."
        case .follicular:
            return "Appetite tends to be steady and unremarkable here."
        case .ovulation:
            return "Appetite may dip slightly around ovulation for some people."
        case .luteal:
            return "Increased appetite and cravings, especially for carbs and sugar, are common and hormonally driven."
        }
    }

    var skinNote: String {
        switch self {
        case .menstrual:
            return "Skin often calms down as hormone levels bottom out."
        case .follicular:
            return "This is typically when skin looks clearest during the cycle."
        case .ovulation:
            return "Skin may look especially bright here, thanks to peak estrogen."
        case .luteal:
            return "Breakouts are more likely in the final week, as progesterone rises then drops."
        }
    }

    var moodNote: String {
        switch self {
        case .menstrual:
            return "Mood often steadies once the period actually starts, even if the days before were rough."
        case .follicular:
            return "Mood tends to be more even and upbeat as estrogen rises."
        case .ovulation:
            return "Confidence and sociability are commonly reported as highest here."
        case .luteal:
            return "Mood swings, irritability, or low mood are common in the last week. It's hormonal, not a character flaw."
        }
    }

    var weightNote: String {
        switch self {
        case .menstrual:
            return "Any water weight from before often starts to release now. The scale isn't a reliable read on this phase."
        case .follicular:
            return "Weight tends to feel most stable here, since water retention is at its lowest."
        case .ovulation:
            return "A slight, temporary bump in water weight is common around ovulation."
        case .luteal:
            return "Feeling heavier or seeing the scale go up here is expected and temporary. It's water retention from progesterone, not fat gain."
        }
    }
}
