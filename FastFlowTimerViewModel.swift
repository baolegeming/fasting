import Foundation
import Combine
import SwiftData
import UserNotifications

enum FastFlowDefaultsKey {
    static let targetPlanType = "targetPlanType"
    static let targetDurationSec = "targetDurationSec"
    static let startReminderEnabled = "startReminderEnabled"
    static let phasePushEnabled = "phasePushEnabled"
    static let oneHourPushEnabled = "oneHourPushEnabled"
    static let startReminderHour = "startReminderHour"
    static let startReminderMinute = "startReminderMinute"
    static let isPro = "isPro"
    static let adInventoryMode = "adInventoryMode"
    static let onboardingCompleted = "onboardingCompleted"
    static let notificationPermissionRequested = "notificationPermissionRequested"
    static let weightEntries = "weightEntries"
    static let appLanguage = "appLanguage"
    static let sessionFeedbackEntries = "sessionFeedbackEntries"
}

enum AbortReason: String, CaseIterable, Identifiable {
    case hungry
    case social
    case unwell
    case planAdjustment = "plan_adjustment"
    case other

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .hungry: return "😰"
        case .social: return "🍽"
        case .unwell: return "🤒"
        case .planAdjustment: return "🛠"
        case .other: return "💬"
        }
    }

    var title: String {
        switch self {
        case .hungry: return AppL10n.string("abort.reason.hungry")
        case .social: return AppL10n.string("abort.reason.social")
        case .unwell: return AppL10n.string("abort.reason.unwell")
        case .planAdjustment: return AppL10n.string("abort.reason.plan_adjustment")
        case .other: return AppL10n.string("abort.reason.other")
        }
    }
}

struct PhaseInfo: Identifiable, Equatable {
    let id: String
    let icon: String
    let nameKey: String
    let timeRangeKey: String
    let descriptionKey: String
    let lowerBoundSec: TimeInterval
    let upperBoundSec: TimeInterval?
    let stageIndex: Int
    let shortLabelKey: String
    let cardSymbol: String

    var name: String { AppL10n.string(nameKey) }
    var timeRange: String { AppL10n.string(timeRangeKey) }
    var description: String { AppL10n.string(descriptionKey) }
    var shortLabel: String { AppL10n.string(shortLabelKey) }

    static let all: [PhaseInfo] = [
        .init(
            id: "digesting",
            icon: "🍽️",
            nameKey: "phase.digesting.name",
            timeRangeKey: "phase.digesting.time",
            descriptionKey: "phase.digesting.desc",
            lowerBoundSec: 0,
            upperBoundSec: 4 * 3600,
            stageIndex: 1,
            shortLabelKey: "phase.digesting.short",
            cardSymbol: "checkmark.circle.fill"
        ),
        .init(
            id: "transition",
            icon: "🌙",
            nameKey: "phase.transition.name",
            timeRangeKey: "phase.transition.time",
            descriptionKey: "phase.transition.desc",
            lowerBoundSec: 4 * 3600,
            upperBoundSec: 8 * 3600,
            stageIndex: 2,
            shortLabelKey: "phase.transition.short",
            cardSymbol: "checkmark.circle.fill"
        ),
        .init(
            id: "metabolic_switch",
            icon: "⚡️",
            nameKey: "phase.metabolic_switch.name",
            timeRangeKey: "phase.metabolic_switch.time",
            descriptionKey: "phase.metabolic_switch.desc",
            lowerBoundSec: 8 * 3600,
            upperBoundSec: 12 * 3600,
            stageIndex: 3,
            shortLabelKey: "phase.metabolic_switch.short",
            cardSymbol: "bolt.fill"
        ),
        .init(
            id: "fat_fuel",
            icon: "🔥",
            nameKey: "phase.fat_fuel.name",
            timeRangeKey: "phase.fat_fuel.time",
            descriptionKey: "phase.fat_fuel.desc",
            lowerBoundSec: 12 * 3600,
            upperBoundSec: 16 * 3600,
            stageIndex: 4,
            shortLabelKey: "phase.fat_fuel.short",
            cardSymbol: "flame.fill"
        ),
        .init(
            id: "deep_cleanup",
            icon: "🫧",
            nameKey: "phase.deep_cleanup.name",
            timeRangeKey: "phase.deep_cleanup.time",
            descriptionKey: "phase.deep_cleanup.desc",
            lowerBoundSec: 16 * 3600,
            upperBoundSec: 24 * 3600,
            stageIndex: 5,
            shortLabelKey: "phase.deep_cleanup.short",
            cardSymbol: "lock.fill"
        ),
        .init(
            id: "breakthrough",
            icon: "🚀",
            nameKey: "phase.breakthrough.name",
            timeRangeKey: "phase.breakthrough.time",
            descriptionKey: "phase.breakthrough.desc",
            lowerBoundSec: 24 * 3600,
            upperBoundSec: nil,
            stageIndex: 6,
            shortLabelKey: "phase.breakthrough.short",
            cardSymbol: "lock.fill"
        )
    ]
}

struct FastFlowPhaseItem: Identifiable {
    let id: String
    let title: String
    let symbol: String
}

@MainActor
final class FastFlowTimerViewModel: ObservableObject {
    @Published var status: FastFlowTimerStatus = .notStarted
    @Published var elapsedText: String = "00:00:00"
    @Published var remainingText: String = AppL10n.string("timer.ready.subtitle")
    @Published var ringProgress: Double = 0.02
    @Published var timerEmoji: String = "⏱️"
    @Published var timerTitle: String = AppL10n.string("timer.ready.title")
    @Published var currentPhase: PhaseInfo = PhaseInfo.all[0]
    @Published var phaseModalInfo: PhaseInfo = PhaseInfo.all[0]
    @Published var activeStageCount: Int = 0
    @Published var phaseBadgeText: String = AppL10n.format("timer.stage.format", 0, 6)
    @Published var phaseItems: [FastFlowPhaseItem] = PhaseInfo.all.map {
        FastFlowPhaseItem(id: $0.id, title: $0.shortLabel, symbol: $0.cardSymbol)
    }
    @Published var showPhaseModal: Bool = false
    @Published var showEndFeedbackSheet: Bool = false
    @Published var pendingSessionResult: FastingSessionResultStatus?
    @Published var coachNote: FastingCoachNote?
    @Published var targetPlanType: String
    @Published var targetDurationSec: Int

    private var startAt: Date?
    private var elapsedSec: TimeInterval = 0
    private var lastPhaseId: String?
    private var timerCancellable: AnyCancellable?
    private var modelContext: ModelContext?
    private var currentRecordID: UUID?

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: FastFlowDefaultsKey.phasePushEnabled) == nil {
            defaults.set(true, forKey: FastFlowDefaultsKey.phasePushEnabled)
        }
        if defaults.object(forKey: FastFlowDefaultsKey.oneHourPushEnabled) == nil {
            defaults.set(true, forKey: FastFlowDefaultsKey.oneHourPushEnabled)
        }
        let storedPlan = defaults.string(forKey: FastFlowDefaultsKey.targetPlanType) ?? "16_8"
        let storedDuration = defaults.integer(forKey: FastFlowDefaultsKey.targetDurationSec)
        let storedOption = PlanOption.option(for: storedPlan)
        let isStoredCustom = PlanOption.isCustom(type: storedPlan)
        if isStoredCustom, let customHours = PlanOption.customFastingHours(for: storedDuration) {
            self.targetPlanType = PlanOption.customType
            self.targetDurationSec = customHours * 3600
        } else {
            let migratedPlan: PlanOption = storedPlan == "5_2" ? .plan16_8 : (storedOption ?? .plan16_8)
            self.targetPlanType = migratedPlan.type
            self.targetDurationSec = storedDuration > 0 && storedOption != nil ? storedDuration : migratedPlan.durationSec
        }

        if storedPlan != self.targetPlanType || storedDuration != self.targetDurationSec {
            defaults.set(self.targetPlanType, forKey: FastFlowDefaultsKey.targetPlanType)
            defaults.set(self.targetDurationSec, forKey: FastFlowDefaultsKey.targetDurationSec)
        }
        bindTicker()
        syncDisplay(now: Date())
    }

    var targetDurationSeconds: Int {
        targetDurationSec
    }

    var ongoingStartAt: Date? {
        status == .fasting ? startAt : nil
    }

    var hasReachedGoal: Bool {
        status == .fasting && elapsedSec >= TimeInterval(targetDurationSec)
    }

    deinit {
        timerCancellable?.cancel()
    }

    func configure(modelContext: ModelContext) {
        if self.modelContext == nil {
            self.modelContext = modelContext
            restoreOngoingFastIfNeeded()
        }
    }

    func startFast() {
        coachNote = nil
        status = .fasting
        let startedAt = Date()
        startAt = startedAt
        elapsedSec = 0
        let newRecordID = UUID()
        currentRecordID = newRecordID
        let initial = phase(for: 0)
        currentPhase = initial
        phaseModalInfo = initial
        lastPhaseId = initial.id
        showPhaseModal = false
        showEndFeedbackSheet = false
        pendingSessionResult = nil
        insertOngoingRecord(recordID: newRecordID, startedAt: startedAt)
        refreshScheduledNotifications()
        syncDisplay(now: Date())
    }

    func requestEndCurrentFast() {
        guard status == .fasting else { return }
        pendingSessionResult = hasReachedGoal ? .completed : .notCompleted
        showEndFeedbackSheet = true
    }

    func dismissEndFeedbackSheet() {
        showEndFeedbackSheet = false
        pendingSessionResult = nil
    }

    func completeFast(
        subjectiveFeeling: FastingSubjectiveFeeling,
        completedObjectiveState: FastingCompletedObjectiveState,
        feedbackStore: FastingSessionFeedbackStore
    ) {
        let endedAt = Date()
        guard let startAt, let currentRecordID else { return }
        let duration = max(0, endedAt.timeIntervalSince(startAt))
        let metGoal = duration >= TimeInterval(targetDurationSec)
        updateCurrentRecord(
            endedAt: endedAt,
            status: FastingRecordStatus.completed,
            isGoalMet: metGoal,
            abortReason: nil
        )
        feedbackStore.upsert(
            FastingSessionFeedbackEntry(
                recordID: currentRecordID,
                resultStatus: .completed,
                subjectiveFeeling: subjectiveFeeling,
                completedObjectiveState: completedObjectiveState,
                notCompletedReason: nil,
                planType: targetPlanType,
                targetDurationSec: targetDurationSec,
                startAt: startAt,
                endAt: endedAt
            )
        )
        resetToIdleState()
    }

    func endFastEarly(
        subjectiveFeeling: FastingSubjectiveFeeling,
        reason: FastingNotCompletedReason,
        feedbackStore: FastingSessionFeedbackStore
    ) {
        let endedAt = Date()
        guard let startAt, let currentRecordID else { return }
        let mappedReason = AbortReason(rawValue: reason.legacyAbortReason) ?? .other
        coachNote = FastingCoachingGuidance.noteAfterAbort(
            reason: mappedReason,
            planType: targetPlanType,
            durationSec: targetDurationSec,
            recommendedReminderMinute: recommendedStartReminderMinute(fallbackStartAt: startAt)
        )
        updateCurrentRecord(
            endedAt: endedAt,
            status: FastingRecordStatus.notCompleted,
            isGoalMet: false,
            abortReason: mappedReason.rawValue
        )
        feedbackStore.upsert(
            FastingSessionFeedbackEntry(
                recordID: currentRecordID,
                resultStatus: .notCompleted,
                subjectiveFeeling: subjectiveFeeling,
                completedObjectiveState: nil,
                notCompletedReason: reason,
                planType: targetPlanType,
                targetDurationSec: targetDurationSec,
                startAt: startAt,
                endAt: endedAt
            )
        )
        resetToIdleState()
    }

    private func resetToIdleState() {
        NotificationManager.shared.cancelAllFastingNotifications()
        status = .notStarted
        startAt = nil
        elapsedSec = 0
        lastPhaseId = nil
        showPhaseModal = false
        showEndFeedbackSheet = false
        pendingSessionResult = nil
        currentRecordID = nil
        syncDisplay(now: Date())
    }

    func dismissPhaseModal() {
        showPhaseModal = false
    }

    func dismissCoachNote() {
        coachNote = nil
    }

    func applyCoachAction(
        _ action: FastingCoachAction,
        removeFromCurrentNote: Bool = true,
        completion: @escaping (String) -> Void
    ) {
        switch action.kind {
        case let .applyGentlerPlan(planType, durationSec):
            updatePlan(planType: planType, durationSec: durationSec)
            if removeFromCurrentNote {
                removeCoachAction(id: action.id)
            }
            let planName = PlanOption.displayName(forType: planType, durationSec: durationSec)
            completion(AppL10n.format("coach.plan.updated", planName))
        case let .scheduleStartReminder(hour, minute):
            applyStartReminder(hour: hour, minute: minute) { [weak self] message in
                if removeFromCurrentNote {
                    self?.removeCoachAction(id: action.id)
                }
                completion(message)
            }
        }
    }

    func correctOngoingFast(startAt correctedStartAt: Date, planType: String, durationSec: Int) {
        guard status == .fasting else { return }

        let previousStartAt = startAt ?? correctedStartAt
        let previousPlanType = targetPlanType
        let previousDurationSec = targetDurationSec
        let safeStartAt = min(correctedStartAt, Date())
        persistPlanDefaults(planType: planType, durationSec: durationSec)

        if let record = fetchCurrentRecord() {
            record.startAt = safeStartAt
            record.planType = planType
            record.targetDurationSec = durationSec
            try? modelContext?.save()
        }

        startAt = safeStartAt
        elapsedSec = max(0, Date().timeIntervalSince(safeStartAt))
        let correctedPhase = phase(for: elapsedSec)
        currentPhase = correctedPhase
        phaseModalInfo = correctedPhase
        lastPhaseId = correctedPhase.id
        showPhaseModal = false
        coachNote = FastingCoachingGuidance.noteAfterOngoingCorrection(
            previousStartAt: previousStartAt,
            correctedStartAt: safeStartAt,
            previousPlanType: previousPlanType,
            previousDurationSec: previousDurationSec,
            correctedPlanType: planType,
            correctedDurationSec: durationSec,
            recommendedReminderMinute: recommendedStartReminderMinute(fallbackStartAt: safeStartAt)
        )
        refreshScheduledNotifications()
        syncDisplay(now: Date())
    }

    func discardOngoingFast() {
        guard status == .fasting else { return }

        if let record = fetchCurrentRecord() {
            modelContext?.delete(record)
            try? modelContext?.save()
        }

        coachNote = FastingCoachingGuidance.noteAfterDiscardingOngoingFast()
        resetToIdleState()
    }

    private func bindTicker() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.handleTick(now: now)
            }
    }

    private func handleTick(now: Date) {
        guard status == .fasting, let startAt else {
            return
        }
        elapsedSec = max(0, now.timeIntervalSince(startAt))
        updatePhaseIfNeeded()
        syncDisplay(now: now)
    }

    private func updatePhaseIfNeeded() {
        let nextPhase = phase(for: elapsedSec)
        if currentPhase.id != nextPhase.id {
            currentPhase = nextPhase
        }
        if let lastPhaseId, lastPhaseId != nextPhase.id {
            phaseModalInfo = nextPhase
            showPhaseModal = true
        }
        lastPhaseId = nextPhase.id
    }

    private func syncDisplay(now: Date) {
        if status == .fasting {
            elapsedText = formatHMS(elapsedSec)
            let remaining = max(TimeInterval(targetDurationSec) - elapsedSec, 0)
            remainingText = remaining > 0
                ? AppL10n.format("timer.remaining.format", formatShortDuration(remaining))
                : AppL10n.string("timer.target.reached")
            ringProgress = min(max(elapsedSec / max(TimeInterval(targetDurationSec), 1), 0.02), 1.0)
            timerEmoji = currentPhase.icon
            timerTitle = currentPhase.name
            activeStageCount = currentPhase.stageIndex
            phaseBadgeText = AppL10n.format("timer.stage.format", currentPhase.stageIndex, 6)
        } else {
            elapsedText = "00:00:00"
            remainingText = AppL10n.string("timer.ready.subtitle")
            ringProgress = 0.02
            timerEmoji = "⏱️"
            timerTitle = AppL10n.string("timer.ready.title")
            currentPhase = PhaseInfo.all[0]
            activeStageCount = 0
            phaseBadgeText = AppL10n.format("timer.stage.format", 0, 6)
        }
    }

    func refreshScheduledNotifications() {
        guard status == .fasting, let startAt else {
            NotificationManager.shared.cancelAllFastingNotifications()
            return
        }
        let defaults = UserDefaults.standard
        NotificationManager.shared.scheduleFastingNotifications(
            startAt: startAt,
            elapsedSec: elapsedSec,
            targetDurationSec: targetDurationSec,
            phasePushEnabled: defaults.bool(forKey: FastFlowDefaultsKey.phasePushEnabled),
            oneHourPushEnabled: defaults.bool(forKey: FastFlowDefaultsKey.oneHourPushEnabled)
        )
    }

    private func restoreOngoingFastIfNeeded() {
        guard let modelContext else { return }
        var descriptor = FetchDescriptor<FastingRecord>(
            predicate: #Predicate { record in
                record.status == "ongoing"
            },
            sortBy: [SortDescriptor(\FastingRecord.startAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let record = try? modelContext.fetch(descriptor).first else {
            syncDisplay(now: Date())
            return
        }

        status = .fasting
        startAt = record.startAt
        currentRecordID = record.id
        elapsedSec = max(0, Date().timeIntervalSince(record.startAt))
        let restoredPhase = phase(for: elapsedSec)
        currentPhase = restoredPhase
        phaseModalInfo = restoredPhase
        lastPhaseId = restoredPhase.id
        showPhaseModal = false
        showEndFeedbackSheet = false
        pendingSessionResult = nil
        refreshScheduledNotifications()
        syncDisplay(now: Date())
    }

    private func insertOngoingRecord(recordID: UUID, startedAt: Date) {
        guard let modelContext else { return }
        let record = FastingRecord(
            id: recordID,
            planType: targetPlanType,
            targetDurationSec: targetDurationSec,
            startAt: startedAt,
            endAt: nil,
            status: FastingRecordStatus.ongoing,
            isGoalMet: false,
            abortReason: nil
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    private func updateCurrentRecord(
        endedAt: Date,
        status: String,
        isGoalMet: Bool,
        abortReason: String?
    ) {
        if let record = fetchCurrentRecord() {
            record.endAt = endedAt
            record.status = status
            record.isGoalMet = isGoalMet
            record.abortReason = abortReason
            try? modelContext?.save()
        }
    }

    func updatePlan(planType: String, durationSec: Int) {
        targetPlanType = planType
        targetDurationSec = durationSec
        persistPlanDefaults(planType: planType, durationSec: durationSec)
        if status == .fasting {
            syncDisplay(now: Date())
        }
    }

    private func fetchCurrentRecord() -> FastingRecord? {
        guard let modelContext, let currentRecordID else { return nil }
        let descriptor = FetchDescriptor<FastingRecord>(
            predicate: #Predicate { record in
                record.id == currentRecordID
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchAllRecords() -> [FastingRecord] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<FastingRecord>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func persistPlanDefaults(planType: String, durationSec: Int) {
        UserDefaults.standard.set(planType, forKey: FastFlowDefaultsKey.targetPlanType)
        UserDefaults.standard.set(durationSec, forKey: FastFlowDefaultsKey.targetDurationSec)
        targetPlanType = planType
        targetDurationSec = durationSec
    }

    private func removeCoachAction(id: UUID) {
        guard var note = coachNote else { return }
        note.actions.removeAll { $0.id == id }
        coachNote = note
    }

    private func recommendedStartReminderMinute(fallbackStartAt: Date? = nil) -> Int? {
        let consistency = FastingAnalytics.startConsistency(records: fetchAllRecords())
        if let typicalStartMinute = consistency.typicalStartMinute {
            return typicalStartMinute
        }

        guard let fallbackStartAt else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: fallbackStartAt)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func applyStartReminder(hour: Int, minute: Int, completion: @escaping (String) -> Void) {
        let defaults = UserDefaults.standard
        defaults.set(hour, forKey: FastFlowDefaultsKey.startReminderHour)
        defaults.set(minute, forKey: FastFlowDefaultsKey.startReminderMinute)

        NotificationManager.shared.getAuthorizationStatus { status in
            switch status {
            case .authorized, .provisional, .ephemeral:
                defaults.set(true, forKey: FastFlowDefaultsKey.startReminderEnabled)
                defaults.set(true, forKey: FastFlowDefaultsKey.notificationPermissionRequested)
                NotificationManager.shared.scheduleStartReminder(hour: hour, minute: minute)
                completion(AppL10n.format("coach.reminder.set", self.formattedReminderTime(hour: hour, minute: minute)))
            case .notDetermined:
                NotificationManager.shared.requestAuthorization { granted in
                    defaults.set(true, forKey: FastFlowDefaultsKey.notificationPermissionRequested)
                    if granted {
                        defaults.set(true, forKey: FastFlowDefaultsKey.startReminderEnabled)
                        NotificationManager.shared.scheduleStartReminder(hour: hour, minute: minute)
                        completion(AppL10n.format("coach.reminder.set", self.formattedReminderTime(hour: hour, minute: minute)))
                    } else {
                        defaults.set(false, forKey: FastFlowDefaultsKey.startReminderEnabled)
                        completion(AppL10n.format("coach.reminder.saved_pending", self.formattedReminderTime(hour: hour, minute: minute)))
                    }
                }
            case .denied:
                defaults.set(false, forKey: FastFlowDefaultsKey.startReminderEnabled)
                defaults.set(true, forKey: FastFlowDefaultsKey.notificationPermissionRequested)
                completion(AppL10n.format("coach.reminder.saved_denied", self.formattedReminderTime(hour: hour, minute: minute)))
            @unknown default:
                defaults.set(false, forKey: FastFlowDefaultsKey.startReminderEnabled)
                completion(AppL10n.string("coach.reminder.saved_unknown"))
            }
        }
    }

    private func formattedReminderTime(hour: Int, minute: Int) -> String {
        let formatter = AppL10n.formatter(dateFormat: "HH:mm")
        let date = Calendar.current.date(
            from: DateComponents(hour: hour, minute: minute)
        ) ?? Date()
        return formatter.string(from: date)
    }

    private func phase(for elapsedSec: TimeInterval) -> PhaseInfo {
        for phase in PhaseInfo.all {
            if let upperBound = phase.upperBoundSec {
                if elapsedSec >= phase.lowerBoundSec && elapsedSec < upperBound {
                    return phase
                }
            } else if elapsedSec >= phase.lowerBoundSec {
                return phase
            }
        }
        return PhaseInfo.all[0]
    }

    private func formatHMS(_ seconds: TimeInterval) -> String {
        let value = Int(seconds)
        let h = value / 3600
        let m = (value % 3600) / 60
        let s = value % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func formatShortDuration(_ seconds: TimeInterval) -> String {
        let value = Int(seconds)
        let h = value / 3600
        let m = (value % 3600) / 60
        if h > 0 {
            return AppL10n.format("duration.short.hours_minutes", h, m)
        }
        return AppL10n.format("duration.short.minutes", m)
    }
}
