import Foundation
import Combine
import SwiftData

struct SyncedPreferencesSnapshot {
    var planType: String
    var targetDurationSec: Int
    var startReminderEnabled: Bool
    var phasePushEnabled: Bool
    var oneHourPushEnabled: Bool
    var startReminderHour: Int
    var startReminderMinute: Int
    var appLanguage: AppLanguage
}

@MainActor
final class SyncedPreferencesStore: ObservableObject {
    @Published private(set) var planType: String
    @Published private(set) var targetDurationSec: Int
    @Published private(set) var startReminderEnabled: Bool
    @Published private(set) var phasePushEnabled: Bool
    @Published private(set) var oneHourPushEnabled: Bool
    @Published private(set) var startReminderHour: Int
    @Published private(set) var startReminderMinute: Int
    @Published private(set) var appLanguage: AppLanguage

    private let defaults: UserDefaults
    private let modelContext: ModelContext?
    private var recordID: PersistentIdentifier?

    init(
        modelContext: ModelContext? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        self.modelContext = modelContext

        let fallback = SyncedPreferencesStore.resolveFallbackSnapshot(defaults: defaults)
        self.planType = fallback.planType
        self.targetDurationSec = fallback.targetDurationSec
        self.startReminderEnabled = fallback.startReminderEnabled
        self.phasePushEnabled = fallback.phasePushEnabled
        self.oneHourPushEnabled = fallback.oneHourPushEnabled
        self.startReminderHour = fallback.startReminderHour
        self.startReminderMinute = fallback.startReminderMinute
        self.appLanguage = fallback.appLanguage

        if modelContext != nil {
            loadOrCreateRecord()
            refreshFromStore()
        } else {
            mirrorToDefaults(snapshot: fallback)
        }
    }

    var snapshot: SyncedPreferencesSnapshot {
        SyncedPreferencesSnapshot(
            planType: planType,
            targetDurationSec: targetDurationSec,
            startReminderEnabled: startReminderEnabled,
            phasePushEnabled: phasePushEnabled,
            oneHourPushEnabled: oneHourPushEnabled,
            startReminderHour: startReminderHour,
            startReminderMinute: startReminderMinute,
            appLanguage: appLanguage
        )
    }

    func updatePlan(planType: String, durationSec: Int) {
        apply {
            $0.planType = planType
            $0.targetDurationSec = durationSec
        }
    }

    func setStartReminderEnabled(_ enabled: Bool) {
        apply {
            $0.startReminderEnabled = enabled
        }
    }

    func setPhasePushEnabled(_ enabled: Bool) {
        apply {
            $0.phasePushEnabled = enabled
        }
    }

    func setOneHourPushEnabled(_ enabled: Bool) {
        apply {
            $0.oneHourPushEnabled = enabled
        }
    }

    func setReminderTime(hour: Int, minute: Int) {
        apply {
            $0.startReminderHour = hour
            $0.startReminderMinute = minute
        }
    }

    func setLanguage(_ language: AppLanguage) {
        apply {
            $0.appLanguage = language
        }
    }

    func refreshFromStore() {
        guard let record = currentRecord() else { return }
        let refreshed = SyncedPreferencesSnapshot(
            planType: record.planType,
            targetDurationSec: record.targetDurationSec,
            startReminderEnabled: record.startReminderEnabled,
            phasePushEnabled: record.phasePushEnabled,
            oneHourPushEnabled: record.oneHourPushEnabled,
            startReminderHour: record.startReminderHour,
            startReminderMinute: record.startReminderMinute,
            appLanguage: AppLanguage(rawValue: record.appLanguageRaw) ?? .defaultValue()
        )

        planType = refreshed.planType
        targetDurationSec = refreshed.targetDurationSec
        startReminderEnabled = refreshed.startReminderEnabled
        phasePushEnabled = refreshed.phasePushEnabled
        oneHourPushEnabled = refreshed.oneHourPushEnabled
        startReminderHour = refreshed.startReminderHour
        startReminderMinute = refreshed.startReminderMinute
        appLanguage = refreshed.appLanguage
        mirrorToDefaults(snapshot: refreshed)
    }

    private func apply(_ mutation: (inout SyncedPreferencesSnapshot) -> Void) {
        var next = snapshot
        mutation(&next)

        planType = next.planType
        targetDurationSec = next.targetDurationSec
        startReminderEnabled = next.startReminderEnabled
        phasePushEnabled = next.phasePushEnabled
        oneHourPushEnabled = next.oneHourPushEnabled
        startReminderHour = next.startReminderHour
        startReminderMinute = next.startReminderMinute
        appLanguage = next.appLanguage

        mirrorToDefaults(snapshot: next)
        persist(snapshot: next)
    }

    private func loadOrCreateRecord() {
        guard let modelContext else { return }

        if let record = currentRecord() {
            recordID = record.persistentModelID
            return
        }

        let initial = snapshot
        let record = SyncedPreferencesRecord(
            planType: initial.planType,
            targetDurationSec: initial.targetDurationSec,
            startReminderEnabled: initial.startReminderEnabled,
            phasePushEnabled: initial.phasePushEnabled,
            oneHourPushEnabled: initial.oneHourPushEnabled,
            startReminderHour: initial.startReminderHour,
            startReminderMinute: initial.startReminderMinute,
            appLanguageRaw: initial.appLanguage.rawValue
        )
        modelContext.insert(record)
        saveChanges()
        recordID = record.persistentModelID
    }

    private func persist(snapshot: SyncedPreferencesSnapshot) {
        guard let record = currentRecord() else { return }
        record.planType = snapshot.planType
        record.targetDurationSec = snapshot.targetDurationSec
        record.startReminderEnabled = snapshot.startReminderEnabled
        record.phasePushEnabled = snapshot.phasePushEnabled
        record.oneHourPushEnabled = snapshot.oneHourPushEnabled
        record.startReminderHour = snapshot.startReminderHour
        record.startReminderMinute = snapshot.startReminderMinute
        record.appLanguageRaw = snapshot.appLanguage.rawValue
        record.updatedAt = Date()
        saveChanges()
    }

    private func currentRecord() -> SyncedPreferencesRecord? {
        guard let modelContext else { return nil }

        if let recordID,
           let record = modelContext.model(for: recordID) as? SyncedPreferencesRecord {
            return record
        }

        let descriptor = FetchDescriptor<SyncedPreferencesRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        if let record = try? modelContext.fetch(descriptor).first {
            recordID = record.persistentModelID
            return record
        }
        return nil
    }

    private func saveChanges() {
        guard let modelContext, modelContext.hasChanges else { return }
        try? modelContext.save()
    }

    private func mirrorToDefaults(snapshot: SyncedPreferencesSnapshot) {
        defaults.set(snapshot.planType, forKey: FastFlowDefaultsKey.targetPlanType)
        defaults.set(snapshot.targetDurationSec, forKey: FastFlowDefaultsKey.targetDurationSec)
        defaults.set(snapshot.startReminderEnabled, forKey: FastFlowDefaultsKey.startReminderEnabled)
        defaults.set(snapshot.phasePushEnabled, forKey: FastFlowDefaultsKey.phasePushEnabled)
        defaults.set(snapshot.oneHourPushEnabled, forKey: FastFlowDefaultsKey.oneHourPushEnabled)
        defaults.set(snapshot.startReminderHour, forKey: FastFlowDefaultsKey.startReminderHour)
        defaults.set(snapshot.startReminderMinute, forKey: FastFlowDefaultsKey.startReminderMinute)
        defaults.set(snapshot.appLanguage.rawValue, forKey: FastFlowDefaultsKey.appLanguage)
    }

    private static func resolveFallbackSnapshot(defaults: UserDefaults) -> SyncedPreferencesSnapshot {
        if defaults.object(forKey: FastFlowDefaultsKey.phasePushEnabled) == nil {
            defaults.set(true, forKey: FastFlowDefaultsKey.phasePushEnabled)
        }
        if defaults.object(forKey: FastFlowDefaultsKey.oneHourPushEnabled) == nil {
            defaults.set(true, forKey: FastFlowDefaultsKey.oneHourPushEnabled)
        }

        let storedPlan = defaults.string(forKey: FastFlowDefaultsKey.targetPlanType) ?? PlanOption.plan16_8.type
        let storedDuration = defaults.integer(forKey: FastFlowDefaultsKey.targetDurationSec)
        let storedOption = PlanOption.option(for: storedPlan)
        let isStoredCustom = PlanOption.isCustom(type: storedPlan)

        let resolvedPlanType: String
        let resolvedDurationSec: Int
        if isStoredCustom, let customHours = PlanOption.customFastingHours(for: storedDuration) {
            resolvedPlanType = PlanOption.customType
            resolvedDurationSec = customHours * 3600
        } else {
            let migratedPlan: PlanOption = storedPlan == "5_2" ? .plan16_8 : (storedOption ?? .plan16_8)
            resolvedPlanType = migratedPlan.type
            resolvedDurationSec = storedDuration > 0 && storedOption != nil ? storedDuration : migratedPlan.durationSec
        }

        let resolvedLanguage = AppLanguage.resolved(from: defaults)
        return SyncedPreferencesSnapshot(
            planType: resolvedPlanType,
            targetDurationSec: resolvedDurationSec,
            startReminderEnabled: defaults.bool(forKey: FastFlowDefaultsKey.startReminderEnabled),
            phasePushEnabled: defaults.bool(forKey: FastFlowDefaultsKey.phasePushEnabled),
            oneHourPushEnabled: defaults.bool(forKey: FastFlowDefaultsKey.oneHourPushEnabled),
            startReminderHour: defaults.object(forKey: FastFlowDefaultsKey.startReminderHour) as? Int ?? 20,
            startReminderMinute: defaults.object(forKey: FastFlowDefaultsKey.startReminderMinute) as? Int ?? 0,
            appLanguage: resolvedLanguage
        )
    }
}
