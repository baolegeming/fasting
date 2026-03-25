import Foundation

enum FastingEducationSurface: String, CaseIterable {
    case onboarding
    case timer
    case phaseModal
    case notification
    case history
    case stats
    case weeklyReport
}

struct FastingEducationReference: Hashable {
    let title: String
    let source: String
    let url: String
    let noteKey: String

    var note: String {
        AppL10n.string(noteKey)
    }
}

struct FastingEducationEntry: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let shortSummaryKey: String
    let userFacingBodyKey: String
    let productImplicationKeys: [String]
    let analyticsImplicationKeys: [String]
    let suggestedSurfaces: [FastingEducationSurface]
    let references: [FastingEducationReference]

    var title: String { AppL10n.string(titleKey) }
    var shortSummary: String { AppL10n.string(shortSummaryKey) }
    var userFacingBody: String { AppL10n.string(userFacingBodyKey) }
    var productImplications: [String] { productImplicationKeys.map(AppL10n.string) }
    var analyticsImplications: [String] { analyticsImplicationKeys.map(AppL10n.string) }
}

enum FastingProductGuardrail: String, CaseIterable {
    case phasesAreEducational
    case sessionIsPrimaryTruth
    case timingMattersMoreThanMidnight

    var title: String {
        switch self {
        case .phasesAreEducational:
            return AppL10n.string("education.guardrail.phase.title")
        case .sessionIsPrimaryTruth:
            return AppL10n.string("education.guardrail.session.title")
        case .timingMattersMoreThanMidnight:
            return AppL10n.string("education.guardrail.midnight.title")
        }
    }

    var guidance: String {
        switch self {
        case .phasesAreEducational:
            return AppL10n.string("education.guardrail.phase.guidance")
        case .sessionIsPrimaryTruth:
            return AppL10n.string("education.guardrail.session.guidance")
        case .timingMattersMoreThanMidnight:
            return AppL10n.string("education.guardrail.midnight.guidance")
        }
    }
}

enum FastingEducationLibrary {
    static let durationFirst = FastingEducationEntry(
        id: "duration_first",
        titleKey: "education.duration.title",
        shortSummaryKey: "education.duration.summary",
        userFacingBodyKey: "education.duration.body",
        productImplicationKeys: [
            "education.duration.product1",
            "education.duration.product2",
            "education.duration.product3"
        ],
        analyticsImplicationKeys: [
            "education.duration.analytics1",
            "education.duration.analytics2"
        ],
        suggestedSurfaces: [.onboarding, .timer, .history, .stats, .weeklyReport],
        references: [
            .init(
                title: "Early Time-Restricted Feeding Improves Insulin Sensitivity, Blood Pressure, and Oxidative Stress Even Without Weight Loss in Men with Prediabetes",
                source: "Cell Metabolism / PMC",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5990470/",
                noteKey: "education.duration.ref1"
            ),
            .init(
                title: "Early Time-Restricted Feeding Improves 24-Hour Glucose Levels and Affects Markers of the Circadian Clock, Aging, and Autophagy in Humans",
                source: "Nutrients / PMC",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6627766/",
                noteKey: "education.duration.ref2"
            )
        ]
    )

    static let timingMatters = FastingEducationEntry(
        id: "timing_matters",
        titleKey: "education.timing.title",
        shortSummaryKey: "education.timing.summary",
        userFacingBodyKey: "education.timing.body",
        productImplicationKeys: [
            "education.timing.product1",
            "education.timing.product2",
            "education.timing.product3"
        ],
        analyticsImplicationKeys: [
            "education.timing.analytics1",
            "education.timing.analytics2"
        ],
        suggestedSurfaces: [.onboarding, .notification, .stats, .weeklyReport],
        references: [
            .init(
                title: "Early Time-Restricted Feeding Improves Insulin Sensitivity, Blood Pressure, and Oxidative Stress Even Without Weight Loss in Men with Prediabetes",
                source: "Cell Metabolism / PMC",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5990470/",
                noteKey: "education.timing.ref1"
            ),
            .init(
                title: "Early Time-Restricted Feeding Improves 24-Hour Glucose Levels and Affects Markers of the Circadian Clock, Aging, and Autophagy in Humans",
                source: "Nutrients / PMC",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6627766/",
                noteKey: "education.timing.ref2"
            )
        ]
    )

    static let consistencyMatters = FastingEducationEntry(
        id: "consistency_matters",
        titleKey: "education.consistency.title",
        shortSummaryKey: "education.consistency.summary",
        userFacingBodyKey: "education.consistency.body",
        productImplicationKeys: [
            "education.consistency.product1",
            "education.consistency.product2",
            "education.consistency.product3"
        ],
        analyticsImplicationKeys: [
            "education.consistency.analytics1",
            "education.consistency.analytics2"
        ],
        suggestedSurfaces: [.onboarding, .notification, .history, .stats, .weeklyReport],
        references: [
            .init(
                title: "Top Things to Know: Meal Timing and Frequency: Implications for CVD Prevention",
                source: "American Heart Association",
                url: "https://professional.heart.org/en/science-news/meal-timing-and-frequency-implications-for-cardiovascular-disease-prevention/top-things-to-know",
                noteKey: "education.consistency.ref1"
            )
        ]
    )

    static let sessionBeforeCalendar = FastingEducationEntry(
        id: "session_before_calendar",
        titleKey: "education.session.title",
        shortSummaryKey: "education.session.summary",
        userFacingBodyKey: "education.session.body",
        productImplicationKeys: [
            "education.session.product1",
            "education.session.product2",
            "education.session.product3"
        ],
        analyticsImplicationKeys: [
            "education.session.analytics1",
            "education.session.analytics2"
        ],
        suggestedSurfaces: [.history, .stats, .weeklyReport],
        references: [
            .init(
                title: "Internal Product Inference Based on Fasting Session Physiology",
                source: "FastFlow Product Logic",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC6627766/",
                noteKey: "education.session.ref1"
            )
        ]
    )

    static let all: [FastingEducationEntry] = [
        durationFirst,
        timingMatters,
        consistencyMatters,
        sessionBeforeCalendar
    ]
}
