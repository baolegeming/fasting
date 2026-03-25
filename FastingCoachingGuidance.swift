import Foundation

enum FastingCoachActionKind: Hashable {
    case applyGentlerPlan(planType: String, durationSec: Int)
    case scheduleStartReminder(hour: Int, minute: Int)
}

struct FastingCoachAction: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let kind: FastingCoachActionKind
}

struct FastingCoachNote: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let actionTitle: String
    let actionDetail: String
    let educationEntry: FastingEducationEntry
    var actions: [FastingCoachAction] = []
}

struct FastingPhaseGuidance {
    let title: String
    let body: String
    let tipTitle: String
    let tipBody: String
    let educationEntry: FastingEducationEntry
}

enum FastingCoachingGuidance {
    static func noteAfterAbort(
        reason: AbortReason,
        planType: String,
        durationSec: Int,
        recommendedReminderMinute: Int?
    ) -> FastingCoachNote {
        let planName = PlanOption.displayName(forType: planType, durationSec: durationSec)
        let actions = suggestedAbortActions(
            reason: reason,
            planType: planType,
            durationSec: durationSec,
            recommendedReminderMinute: recommendedReminderMinute
        )

        switch reason {
        case .hungry:
            return FastingCoachNote(
                title: AppL10n.string("coach.abort.hungry.title"),
                body: AppL10n.string("coach.abort.hungry.body"),
                actionTitle: AppL10n.string("coach.action.next_time"),
                actionDetail: AppL10n.format("coach.abort.hungry.detail", planName),
                educationEntry: FastingEducationLibrary.consistencyMatters,
                actions: actions
            )
        case .social:
            return FastingCoachNote(
                title: AppL10n.string("coach.abort.social.title"),
                body: AppL10n.string("coach.abort.social.body"),
                actionTitle: AppL10n.string("coach.action.next_time"),
                actionDetail: AppL10n.string("coach.abort.social.detail"),
                educationEntry: FastingEducationLibrary.consistencyMatters,
                actions: actions
            )
        case .unwell:
            return FastingCoachNote(
                title: AppL10n.string("coach.abort.unwell.title"),
                body: AppL10n.string("coach.abort.unwell.body"),
                actionTitle: AppL10n.string("coach.action.next_time"),
                actionDetail: AppL10n.string("coach.abort.unwell.detail"),
                educationEntry: FastingEducationLibrary.consistencyMatters,
                actions: actions
            )
        case .planAdjustment:
            return FastingCoachNote(
                title: AppL10n.string("coach.abort.plan_adjustment.title"),
                body: AppL10n.string("coach.abort.plan_adjustment.body"),
                actionTitle: AppL10n.string("coach.action.next_time"),
                actionDetail: AppL10n.string("coach.abort.plan_adjustment.detail"),
                educationEntry: FastingEducationLibrary.sessionBeforeCalendar,
                actions: actions
            )
        case .other:
            return FastingCoachNote(
                title: AppL10n.string("coach.abort.other.title"),
                body: AppL10n.string("coach.abort.other.body"),
                actionTitle: AppL10n.string("coach.action.next_time"),
                actionDetail: AppL10n.string("coach.abort.other.detail"),
                educationEntry: FastingEducationLibrary.sessionBeforeCalendar,
                actions: actions
            )
        }
    }

    static func noteAfterOngoingCorrection(
        previousStartAt: Date,
        correctedStartAt: Date,
        previousPlanType: String,
        previousDurationSec: Int,
        correctedPlanType: String,
        correctedDurationSec: Int,
        recommendedReminderMinute: Int?
    ) -> FastingCoachNote {
        let changedStartEarlier = correctedStartAt < previousStartAt.addingTimeInterval(-60)
        let changedPlan = previousPlanType != correctedPlanType || previousDurationSec != correctedDurationSec
        let correctedPlanName = PlanOption.displayName(forType: correctedPlanType, durationSec: correctedDurationSec)
        let reminderMinute = recommendedReminderMinute ?? minutesFromMidnight(for: correctedStartAt)
        let reminderActions = [startReminderAction(minutesFromMidnight: reminderMinute)]

        if changedStartEarlier {
            return FastingCoachNote(
                title: AppL10n.string("coach.ongoing.corrected_start.title"),
                body: AppL10n.string("coach.ongoing.corrected_start.body"),
                actionTitle: AppL10n.string("coach.action.impact"),
                actionDetail: AppL10n.string("coach.ongoing.corrected_start.detail"),
                educationEntry: FastingEducationLibrary.durationFirst,
                actions: reminderActions
            )
        }

        if changedPlan {
            return FastingCoachNote(
                title: AppL10n.string("coach.ongoing.corrected_plan.title"),
                body: AppL10n.string("coach.ongoing.corrected_plan.body"),
                actionTitle: AppL10n.string("coach.action.next_time"),
                actionDetail: AppL10n.format("coach.ongoing.corrected_plan.detail", correctedPlanName),
                educationEntry: FastingEducationLibrary.consistencyMatters,
                actions: reminderActions
            )
        }

        return FastingCoachNote(
            title: AppL10n.string("coach.ongoing.corrected_generic.title"),
            body: AppL10n.string("coach.ongoing.corrected_generic.body"),
            actionTitle: AppL10n.string("coach.action.next_time"),
            actionDetail: AppL10n.string("coach.ongoing.corrected_generic.detail"),
            educationEntry: FastingEducationLibrary.sessionBeforeCalendar,
            actions: reminderActions
        )
    }

    static func noteAfterDiscardingOngoingFast() -> FastingCoachNote {
        FastingCoachNote(
            title: AppL10n.string("coach.ongoing.discarded.title"),
            body: AppL10n.string("coach.ongoing.discarded.body"),
            actionTitle: AppL10n.string("coach.action.next_time"),
            actionDetail: AppL10n.string("coach.ongoing.discarded.detail"),
            educationEntry: FastingEducationLibrary.sessionBeforeCalendar
        )
    }

    static func phaseGuidance(for phase: PhaseInfo) -> FastingPhaseGuidance {
        switch phase.id {
        case "digesting", "transition":
            return FastingPhaseGuidance(
                title: AppL10n.string("coach.phase.early.title"),
                body: AppL10n.string("coach.phase.early.body"),
                tipTitle: AppL10n.string("coach.phase.tip_title"),
                tipBody: AppL10n.string("coach.phase.early.tip"),
                educationEntry: FastingEducationLibrary.durationFirst
            )
        case "metabolic_switch", "fat_fuel":
            return FastingPhaseGuidance(
                title: AppL10n.string("coach.phase.middle.title"),
                body: AppL10n.string("coach.phase.middle.body"),
                tipTitle: AppL10n.string("coach.phase.tip_title"),
                tipBody: AppL10n.string("coach.phase.middle.tip"),
                educationEntry: FastingEducationLibrary.sessionBeforeCalendar
            )
        default:
            return FastingPhaseGuidance(
                title: AppL10n.string("coach.phase.late.title"),
                body: AppL10n.string("coach.phase.late.body"),
                tipTitle: AppL10n.string("coach.phase.tip_title"),
                tipBody: AppL10n.string("coach.phase.late.tip"),
                educationEntry: FastingEducationLibrary.consistencyMatters
            )
        }
    }

    static func weeklyActionSteps(for report: FastingWeeklyReport) -> [String] {
        switch report.focus {
        case .keepRhythm:
            return [
                AppL10n.string("coach.weekly.keep.step1"),
                AppL10n.string("coach.weekly.keep.step2"),
                AppL10n.string("coach.weekly.keep.step3")
            ]
        case .stabilizeStartTime:
            return [
                AppL10n.string("coach.weekly.stabilize.step1"),
                AppL10n.string("coach.weekly.stabilize.step2"),
                AppL10n.string("coach.weekly.stabilize.step3")
            ]
        case .improveCompletion:
            return [
                AppL10n.string("coach.weekly.improve.step1"),
                AppL10n.string("coach.weekly.improve.step2"),
                AppL10n.string("coach.weekly.improve.step3")
            ]
        case .gentlerPlan:
            return [
                AppL10n.string("coach.weekly.gentler.step1"),
                AppL10n.string("coach.weekly.gentler.step2"),
                AppL10n.string("coach.weekly.gentler.step3")
            ]
        case .buildHabit:
            return [
                AppL10n.string("coach.weekly.build.step1"),
                AppL10n.string("coach.weekly.build.step2"),
                AppL10n.string("coach.weekly.build.step3")
            ]
        }
    }

    static func weeklyActionHeadline(for report: FastingWeeklyReport) -> String {
        switch report.focus {
        case .keepRhythm:
            return AppL10n.string("coach.weekly.headline.keep")
        case .stabilizeStartTime:
            return AppL10n.string("coach.weekly.headline.stabilize")
        case .improveCompletion:
            return AppL10n.string("coach.weekly.headline.improve")
        case .gentlerPlan:
            return AppL10n.string("coach.weekly.headline.gentler")
        case .buildHabit:
            return AppL10n.string("coach.weekly.headline.build")
        }
    }

    static func weeklyActionButtons(
        for report: FastingWeeklyReport,
        currentPlanType: String,
        currentDurationSec: Int
    ) -> [FastingCoachAction] {
        var actions: [FastingCoachAction] = []

        if let reminderMinute = report.startConsistency.typicalStartMinute {
            actions.append(startReminderAction(minutesFromMidnight: reminderMinute))
        }

        if report.focus == .gentlerPlan,
           let gentlerPlan = gentlerPlanAction(forType: currentPlanType, durationSec: currentDurationSec) {
            actions.insert(gentlerPlan, at: 0)
        }

        return actions
    }

    private static func suggestedAbortActions(
        reason: AbortReason,
        planType: String,
        durationSec: Int,
        recommendedReminderMinute: Int?
    ) -> [FastingCoachAction] {
        var actions: [FastingCoachAction] = []

        if reason != .social,
           let gentler = gentlerPlanAction(forType: planType, durationSec: durationSec) {
            actions.append(gentler)
        }

        if let recommendedReminderMinute {
            actions.append(startReminderAction(minutesFromMidnight: recommendedReminderMinute))
        }

        return actions
    }

    private static func gentlerPlanAction(forType type: String, durationSec: Int) -> FastingCoachAction? {
        guard let recommendation = PlanOption.gentlerRecommendation(forType: type, durationSec: durationSec) else {
            return nil
        }

        let planName = PlanOption.displayName(
            forType: recommendation.planType,
            durationSec: recommendation.durationSec
        )
        return FastingCoachAction(
            title: AppL10n.format("coach.action.plan.title", planName),
            detail: AppL10n.string("coach.action.plan.detail"),
            kind: .applyGentlerPlan(planType: recommendation.planType, durationSec: recommendation.durationSec)
        )
    }

    private static func startReminderAction(minutesFromMidnight: Int) -> FastingCoachAction {
        let hour = minutesFromMidnight / 60
        let minute = minutesFromMidnight % 60
        return FastingCoachAction(
            title: AppL10n.format("coach.action.reminder.title", formattedClockTime(hour: hour, minute: minute)),
            detail: AppL10n.string("coach.action.reminder.detail"),
            kind: .scheduleStartReminder(hour: hour, minute: minute)
        )
    }

    private static func minutesFromMidnight(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private static func formattedClockTime(hour: Int, minute: Int) -> String {
        let formatter = AppL10n.formatter(dateFormat: "HH:mm")
        let date = Calendar.current.date(
            from: DateComponents(hour: hour, minute: minute)
        ) ?? Date()
        return formatter.string(from: date)
    }
}
