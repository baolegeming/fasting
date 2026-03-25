import Foundation
import SwiftData

@Model
final class FastingRecord {
    var id: UUID
    var planType: String
    var targetDurationSec: Int
    var startAt: Date
    var endAt: Date?
    var status: String
    var isGoalMet: Bool
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

// Legacy cache model kept for compatibility while metrics move to session-derived analytics.
@Model
final class DailySummary {
    var id: UUID
    var date: Date
    var isGoalMet: Bool
    var statusColor: String
    var totalFastingSec: Int

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

enum FastFlowMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FastFlowSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
