import Foundation

enum PlanOption: CaseIterable {
    case plan16_8
    case plan18_6
    case plan20_4
    case omad

    static let customType = "custom"

    var type: String {
        switch self {
        case .plan16_8: return "16_8"
        case .plan18_6: return "18_6"
        case .plan20_4: return "20_4"
        case .omad: return "OMAD"
        }
    }

    var name: String {
        switch self {
        case .plan16_8: return "16:8"
        case .plan18_6: return "18:6"
        case .plan20_4: return "20:4"
        case .omad: return "OMAD"
        }
    }

    var durationSec: Int {
        switch self {
        case .plan16_8: return 16 * 3600
        case .plan18_6: return 18 * 3600
        case .plan20_4: return 20 * 3600
        case .omad: return 23 * 3600
        }
    }

    static func option(for type: String) -> PlanOption? {
        allCases.first(where: { $0.type == type })
    }

    static func isCustom(type: String) -> Bool {
        type == customType
    }

    static func displayName(forType type: String, durationSec: Int) -> String {
        if let option = option(for: type) {
            return option.name
        }
        if isCustom(type: type), let customName = customRatioName(durationSec: durationSec) {
            return customName
        }
        return "16:8"
    }

    static func customRatioName(durationSec: Int) -> String? {
        guard let fastingHours = customFastingHours(for: durationSec) else { return nil }
        let eatingHours = max(24 - fastingHours, 0)
        return "\(fastingHours):\(eatingHours)"
    }

    static func customFastingHours(for durationSec: Int) -> Int? {
        guard durationSec % 3600 == 0 else { return nil }
        let hours = durationSec / 3600
        guard (12...23).contains(hours) else { return nil }
        return hours
    }

    static func gentlerRecommendation(forType type: String, durationSec: Int) -> (planType: String, durationSec: Int)? {
        if isCustom(type: type), let fastingHours = customFastingHours(for: durationSec) {
            let gentlerHours = max(12, fastingHours - 2)
            guard gentlerHours != fastingHours else { return nil }
            return (customType, gentlerHours * 3600)
        }

        guard let option = option(for: type) else { return nil }
        switch option {
        case .omad:
            return (PlanOption.plan20_4.type, PlanOption.plan20_4.durationSec)
        case .plan20_4:
            return (PlanOption.plan18_6.type, PlanOption.plan18_6.durationSec)
        case .plan18_6:
            return (PlanOption.plan16_8.type, PlanOption.plan16_8.durationSec)
        case .plan16_8:
            return nil
        }
    }
}
