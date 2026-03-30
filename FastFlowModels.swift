import Foundation
import SwiftData

@Model
final class FastingRecord {
    var id: UUID = UUID()
    var planType: String = ""
    var targetDurationSec: Int = 0
    var startAt: Date = Date()
    var endAt: Date?
    var status: String = ""
    var isGoalMet: Bool = false
    var abortReason: String?

    init(
        id: UUID = UUID(),
        planType: String,
        targetDurationSec: Int,
        startAt: Date,
        endAt: Date? = nil,
        status: String,
        isGoalMet: Bool,
        abortReason: String? = nil
    ) {
        self.id = id
        self.planType = planType
        self.targetDurationSec = targetDurationSec
        self.startAt = startAt
        self.endAt = endAt
        self.status = status
        self.isGoalMet = isGoalMet
        self.abortReason = abortReason
    }
}

@Model
final class WeightRecord {
    var id: UUID = UUID()
    var recordedAt: Date = Date()
    var weightKg: Double = 0
    var sourceRaw: String = ""

    init(
        id: UUID = UUID(),
        recordedAt: Date,
        weightKg: Double,
        sourceRaw: String
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.weightKg = weightKg
        self.sourceRaw = sourceRaw
    }
}

@Model
final class SessionFeedbackRecord {
    var id: UUID = UUID()
    var recordID: UUID = UUID()
    var recordedAt: Date = Date()
    var resultStatusRaw: String = ""
    var subjectiveFeelingRaw: String = ""
    var completedObjectiveStateRaw: String?
    var notCompletedReasonRaw: String?
    var planType: String = ""
    var targetDurationSec: Int = 0
    var startAt: Date = Date()
    var endAt: Date = Date()

    init(
        id: UUID = UUID(),
        recordID: UUID,
        recordedAt: Date,
        resultStatusRaw: String,
        subjectiveFeelingRaw: String,
        completedObjectiveStateRaw: String? = nil,
        notCompletedReasonRaw: String? = nil,
        planType: String,
        targetDurationSec: Int,
        startAt: Date,
        endAt: Date
    ) {
        self.id = id
        self.recordID = recordID
        self.recordedAt = recordedAt
        self.resultStatusRaw = resultStatusRaw
        self.subjectiveFeelingRaw = subjectiveFeelingRaw
        self.completedObjectiveStateRaw = completedObjectiveStateRaw
        self.notCompletedReasonRaw = notCompletedReasonRaw
        self.planType = planType
        self.targetDurationSec = targetDurationSec
        self.startAt = startAt
        self.endAt = endAt
    }
}

@Model
final class SyncedPreferencesRecord {
    var id: UUID = UUID()
    var planType: String = ""
    var targetDurationSec: Int = 0
    var startReminderEnabled: Bool = false
    var phasePushEnabled: Bool = false
    var oneHourPushEnabled: Bool = false
    var startReminderHour: Int = 20
    var startReminderMinute: Int = 0
    var appLanguageRaw: String = ""
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        planType: String,
        targetDurationSec: Int,
        startReminderEnabled: Bool,
        phasePushEnabled: Bool,
        oneHourPushEnabled: Bool,
        startReminderHour: Int,
        startReminderMinute: Int,
        appLanguageRaw: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.planType = planType
        self.targetDurationSec = targetDurationSec
        self.startReminderEnabled = startReminderEnabled
        self.phasePushEnabled = phasePushEnabled
        self.oneHourPushEnabled = oneHourPushEnabled
        self.startReminderHour = startReminderHour
        self.startReminderMinute = startReminderMinute
        self.appLanguageRaw = appLanguageRaw
        self.updatedAt = updatedAt
    }
}

// Legacy cache model kept for compatibility while metrics move to session-derived analytics.
@Model
final class DailySummary {
    var id: UUID = UUID()
    var date: Date = Date()
    var isGoalMet: Bool = false
    var statusColor: String = ""
    var totalFastingSec: Int = 0

    init(
        id: UUID = UUID(),
        date: Date,
        isGoalMet: Bool,
        statusColor: String,
        totalFastingSec: Int
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.isGoalMet = isGoalMet
        self.statusColor = statusColor
        self.totalFastingSec = totalFastingSec
    }
}

enum FastFlowSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [FastingRecord.self, DailySummary.self]
    }
}

enum FastFlowSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [FastingRecord.self, DailySummary.self, WeightRecord.self]
    }
}

enum FastFlowSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [FastingRecord.self, DailySummary.self, WeightRecord.self, SessionFeedbackRecord.self]
    }
}

enum FastFlowSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            FastingRecord.self,
            DailySummary.self,
            WeightRecord.self,
            SessionFeedbackRecord.self,
            SyncedPreferencesRecord.self
        ]
    }
}

enum FastFlowMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FastFlowSchemaV1.self, FastFlowSchemaV2.self, FastFlowSchemaV3.self, FastFlowSchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: FastFlowSchemaV1.self, toVersion: FastFlowSchemaV2.self),
            .lightweight(fromVersion: FastFlowSchemaV2.self, toVersion: FastFlowSchemaV3.self),
            .lightweight(fromVersion: FastFlowSchemaV3.self, toVersion: FastFlowSchemaV4.self)
        ]
    }
}
