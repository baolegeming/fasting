import Foundation
import Combine
import SwiftData

enum FastingSessionResultStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case completed
    case notCompleted = "not_completed"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .completed:
            return AppL10n.string("session.result.completed")
        case .notCompleted:
            return AppL10n.string("session.result.not_completed")
        }
    }
}

enum FastingSubjectiveFeeling: String, Codable, CaseIterable, Identifiable, Hashable {
    case easy
    case manageable
    case challenging
    case veryHard = "very_hard"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy:
            return AppL10n.string("session.feeling.easy")
        case .manageable:
            return AppL10n.string("session.feeling.manageable")
        case .challenging:
            return AppL10n.string("session.feeling.challenging")
        case .veryHard:
            return AppL10n.string("session.feeling.very_hard")
        }
    }
}

enum FastingCompletedObjectiveState: String, Codable, CaseIterable, Identifiable, Hashable {
    case steadyEnergy = "steady_energy"
    case slightlyHungry = "slightly_hungry"
    case slightlyTired = "slightly_tired"
    case feltGreat = "felt_great"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steadyEnergy:
            return AppL10n.string("session.completed.steady_energy")
        case .slightlyHungry:
            return AppL10n.string("session.completed.slightly_hungry")
        case .slightlyTired:
            return AppL10n.string("session.completed.slightly_tired")
        case .feltGreat:
            return AppL10n.string("session.completed.felt_great")
        }
    }
}

enum FastingNotCompletedReason: String, Codable, CaseIterable, Identifiable, Hashable {
    case hungry
    case social
    case unwell
    case planAdjustment = "plan_adjustment"
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hungry:
            return AppL10n.string("session.not_completed.hungry")
        case .social:
            return AppL10n.string("session.not_completed.social")
        case .unwell:
            return AppL10n.string("session.not_completed.unwell")
        case .planAdjustment:
            return AppL10n.string("session.not_completed.plan_adjustment")
        case .other:
            return AppL10n.string("session.not_completed.other")
        }
    }

    var legacyAbortReason: String {
        switch self {
        case .hungry:
            return AbortReason.hungry.rawValue
        case .social:
            return AbortReason.social.rawValue
        case .unwell:
            return AbortReason.unwell.rawValue
        case .planAdjustment:
            return AbortReason.planAdjustment.rawValue
        case .other:
            return AbortReason.other.rawValue
        }
    }
}

struct FastingSessionFeedbackEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let recordID: UUID
    let recordedAt: Date
    let resultStatus: FastingSessionResultStatus
    let subjectiveFeeling: FastingSubjectiveFeeling
    let completedObjectiveState: FastingCompletedObjectiveState?
    let notCompletedReason: FastingNotCompletedReason?
    let planType: String
    let targetDurationSec: Int
    let startAt: Date
    let endAt: Date

    init(
        id: UUID = UUID(),
        recordID: UUID,
        recordedAt: Date = Date(),
        resultStatus: FastingSessionResultStatus,
        subjectiveFeeling: FastingSubjectiveFeeling,
        completedObjectiveState: FastingCompletedObjectiveState? = nil,
        notCompletedReason: FastingNotCompletedReason? = nil,
        planType: String,
        targetDurationSec: Int,
        startAt: Date,
        endAt: Date
    ) {
        self.id = id
        self.recordID = recordID
        self.recordedAt = recordedAt
        self.resultStatus = resultStatus
        self.subjectiveFeeling = subjectiveFeeling
        self.completedObjectiveState = completedObjectiveState
        self.notCompletedReason = notCompletedReason
        self.planType = planType
        self.targetDurationSec = targetDurationSec
        self.startAt = startAt
        self.endAt = endAt
    }
}

enum FastingRecordStatus {
    static let ongoing = "ongoing"
    static let completed = FastingSessionResultStatus.completed.rawValue
    static let notCompleted = FastingSessionResultStatus.notCompleted.rawValue
    static let legacyAborted = "aborted"

    static func isCompleted(_ status: String) -> Bool {
        status == completed
    }

    static func isNotCompleted(_ status: String) -> Bool {
        status == notCompleted || status == legacyAborted
    }

    static func isOngoing(_ status: String) -> Bool {
        status == ongoing
    }
}

@MainActor
final class FastingSessionFeedbackStore: ObservableObject {
    @Published private(set) var entries: [FastingSessionFeedbackEntry] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let modelContext: ModelContext?

    init(
        modelContext: ModelContext? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.modelContext = modelContext
        self.defaults = defaults
        if modelContext != nil {
            importLegacyEntriesIfNeeded()
            refreshFromStore()
        } else {
            loadLegacyEntries()
        }
    }

    func upsert(_ entry: FastingSessionFeedbackEntry) {
        if let modelContext {
            if let existingRecord = record(for: entry.recordID, in: modelContext) {
                existingRecord.recordedAt = entry.recordedAt
                existingRecord.resultStatusRaw = entry.resultStatus.rawValue
                existingRecord.subjectiveFeelingRaw = entry.subjectiveFeeling.rawValue
                existingRecord.completedObjectiveStateRaw = entry.completedObjectiveState?.rawValue
                existingRecord.notCompletedReasonRaw = entry.notCompletedReason?.rawValue
                existingRecord.planType = entry.planType
                existingRecord.targetDurationSec = entry.targetDurationSec
                existingRecord.startAt = entry.startAt
                existingRecord.endAt = entry.endAt
            } else {
                let record = SessionFeedbackRecord(
                    id: entry.id,
                    recordID: entry.recordID,
                    recordedAt: entry.recordedAt,
                    resultStatusRaw: entry.resultStatus.rawValue,
                    subjectiveFeelingRaw: entry.subjectiveFeeling.rawValue,
                    completedObjectiveStateRaw: entry.completedObjectiveState?.rawValue,
                    notCompletedReasonRaw: entry.notCompletedReason?.rawValue,
                    planType: entry.planType,
                    targetDurationSec: entry.targetDurationSec,
                    startAt: entry.startAt,
                    endAt: entry.endAt
                )
                modelContext.insert(record)
            }
            saveChanges()
            refreshFromStore()
        } else {
            if let index = entries.firstIndex(where: { $0.recordID == entry.recordID }) {
                entries[index] = entry
            } else {
                entries.append(entry)
            }
            entries.sort { $0.recordedAt > $1.recordedAt }
            persistLegacyEntries()
        }
    }

    func entry(for recordID: UUID) -> FastingSessionFeedbackEntry? {
        entries.first { $0.recordID == recordID }
    }

    func delete(recordID: UUID) {
        if let modelContext, let record = record(for: recordID, in: modelContext) {
            modelContext.delete(record)
            saveChanges()
            refreshFromStore()
        } else {
            entries.removeAll { $0.recordID == recordID }
            persistLegacyEntries()
        }
    }

    private func loadLegacyEntries() {
        guard let data = defaults.data(forKey: FastFlowDefaultsKey.sessionFeedbackEntries) else {
            entries = []
            return
        }

        do {
            entries = try decoder.decode([FastingSessionFeedbackEntry].self, from: data)
                .sorted { $0.recordedAt > $1.recordedAt }
        } catch {
            entries = []
        }
    }

    private func persistLegacyEntries() {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: FastFlowDefaultsKey.sessionFeedbackEntries)
    }

    func refreshFromStore() {
        guard let modelContext else {
            entries = []
            return
        }

        do {
            let descriptor = FetchDescriptor<SessionFeedbackRecord>(
                sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
            )
            let records = try modelContext.fetch(descriptor)
            entries = records.compactMap { record in
                guard
                    let resultStatus = FastingSessionResultStatus(rawValue: record.resultStatusRaw),
                    let subjectiveFeeling = FastingSubjectiveFeeling(rawValue: record.subjectiveFeelingRaw)
                else {
                    return nil
                }

                return FastingSessionFeedbackEntry(
                    id: record.id,
                    recordID: record.recordID,
                    recordedAt: record.recordedAt,
                    resultStatus: resultStatus,
                    subjectiveFeeling: subjectiveFeeling,
                    completedObjectiveState: record.completedObjectiveStateRaw.flatMap(FastingCompletedObjectiveState.init(rawValue:)),
                    notCompletedReason: record.notCompletedReasonRaw.flatMap(FastingNotCompletedReason.init(rawValue:)),
                    planType: record.planType,
                    targetDurationSec: record.targetDurationSec,
                    startAt: record.startAt,
                    endAt: record.endAt
                )
            }
                .sorted { $0.recordedAt > $1.recordedAt }
        } catch {
            entries = []
        }
    }

    private func importLegacyEntriesIfNeeded() {
        guard let modelContext else { return }

        let alreadyMigrated = defaults.bool(forKey: FastFlowDefaultsKey.sessionFeedbackEntriesMigratedToSwiftData)
        guard !alreadyMigrated else { return }

        let legacyEntries = decodeLegacyEntries()
        guard !legacyEntries.isEmpty else {
            defaults.set(true, forKey: FastFlowDefaultsKey.sessionFeedbackEntriesMigratedToSwiftData)
            return
        }

        do {
            let existingRecords = try modelContext.fetch(FetchDescriptor<SessionFeedbackRecord>())
            let existingRecordIDs = Set(existingRecords.map(\.recordID))

            for entry in legacyEntries where !existingRecordIDs.contains(entry.recordID) {
                let record = SessionFeedbackRecord(
                    id: entry.id,
                    recordID: entry.recordID,
                    recordedAt: entry.recordedAt,
                    resultStatusRaw: entry.resultStatus.rawValue,
                    subjectiveFeelingRaw: entry.subjectiveFeeling.rawValue,
                    completedObjectiveStateRaw: entry.completedObjectiveState?.rawValue,
                    notCompletedReasonRaw: entry.notCompletedReason?.rawValue,
                    planType: entry.planType,
                    targetDurationSec: entry.targetDurationSec,
                    startAt: entry.startAt,
                    endAt: entry.endAt
                )
                modelContext.insert(record)
            }

            if modelContext.hasChanges {
                try modelContext.save()
            }

            defaults.set(true, forKey: FastFlowDefaultsKey.sessionFeedbackEntriesMigratedToSwiftData)
        } catch {
            return
        }
    }

    private func decodeLegacyEntries() -> [FastingSessionFeedbackEntry] {
        guard let data = defaults.data(forKey: FastFlowDefaultsKey.sessionFeedbackEntries) else {
            return []
        }

        do {
            return try decoder.decode([FastingSessionFeedbackEntry].self, from: data)
                .sorted { $0.recordedAt > $1.recordedAt }
        } catch {
            return []
        }
    }

    private func record(for recordID: UUID, in modelContext: ModelContext) -> SessionFeedbackRecord? {
        let descriptor = FetchDescriptor<SessionFeedbackRecord>(
            predicate: #Predicate { $0.recordID == recordID }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func saveChanges() {
        guard let modelContext else { return }
        do {
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            return
        }
    }
}
