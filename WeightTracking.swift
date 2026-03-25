import Foundation
import Combine

enum WeightRecordSource: String, Codable {
    case manual
    case healthKit

    var label: String {
        switch self {
        case .manual:
            return AppL10n.string("weight.source.manual")
        case .healthKit:
            return AppL10n.string("weight.source.healthkit")
        }
    }
}

struct WeightEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let recordedAt: Date
    let weightKg: Double
    let source: WeightRecordSource

    init(
        id: UUID = UUID(),
        recordedAt: Date,
        weightKg: Double,
        source: WeightRecordSource
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.weightKg = weightKg
        self.source = source
    }
}

struct WeightTrendPoint: Identifiable {
    let id: UUID
    let date: Date
    let weightKg: Double
}

struct WeightTrendSummary {
    let latestEntry: WeightEntry?
    let baselineEntry: WeightEntry?
    let changeFromBaselineKg: Double?
    let loggingWindowDays: Int
    let averageFastingHoursDuringWindow: Double?
}

@MainActor
final class WeightStore: ObservableObject {
    @Published private(set) var entries: [WeightEntry] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func addEntry(
        weightKg: Double,
        recordedAt: Date,
        source: WeightRecordSource = .manual
    ) {
        let normalizedWeight = (weightKg * 10).rounded() / 10
        let entry = WeightEntry(
            recordedAt: recordedAt,
            weightKg: normalizedWeight,
            source: source
        )

        entries.append(entry)
        entries.sort { $0.recordedAt < $1.recordedAt }
        persist()
    }

    func updateEntry(
        id: UUID,
        weightKg: Double,
        recordedAt: Date,
        source: WeightRecordSource
    ) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let normalizedWeight = (weightKg * 10).rounded() / 10
        entries[index] = WeightEntry(
            id: id,
            recordedAt: recordedAt,
            weightKg: normalizedWeight,
            source: source
        )
        entries.sort { $0.recordedAt < $1.recordedAt }
        persist()
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: FastFlowDefaultsKey.weightEntries) else {
            entries = []
            return
        }

        do {
            entries = try decoder.decode([WeightEntry].self, from: data)
                .sorted { $0.recordedAt < $1.recordedAt }
        } catch {
            entries = []
        }
    }

    private func persist() {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: FastFlowDefaultsKey.weightEntries)
    }
}

enum WeightAnalytics {
    static func summary(
        weightEntries: [WeightEntry],
        fastingRecords: [FastingRecord],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WeightTrendSummary {
        let sortedEntries = weightEntries.sorted { $0.recordedAt < $1.recordedAt }
        let latestEntry = sortedEntries.last
        let baselineEntry = sortedEntries.first
        let changeFromBaselineKg: Double?

        if let latestEntry, let baselineEntry, latestEntry.id != baselineEntry.id {
            changeFromBaselineKg = latestEntry.weightKg - baselineEntry.weightKg
        } else {
            changeFromBaselineKg = nil
        }

        let loggingWindowDays: Int
        let averageFastingHoursDuringWindow: Double?

        if let latestEntry, let baselineEntry {
            let startDay = calendar.startOfDay(for: baselineEntry.recordedAt)
            let endDay = calendar.startOfDay(for: latestEntry.recordedAt)
            loggingWindowDays = max(
                1,
                calendar.dateComponents([.day], from: startDay, to: endDay).day.map { $0 + 1 } ?? 1
            )

            let intervalEnd = calendar.date(byAdding: .day, value: 1, to: endDay) ?? latestEntry.recordedAt
            let interval = DateInterval(start: startDay, end: intervalEnd)
            let averageSeconds = averageFastingSeconds(
                in: interval,
                records: fastingRecords,
                now: now,
                calendar: calendar
            )
            averageFastingHoursDuringWindow = averageSeconds.map { Double($0) / 3600.0 }
        } else {
            loggingWindowDays = 0
            averageFastingHoursDuringWindow = nil
        }

        return WeightTrendSummary(
            latestEntry: latestEntry,
            baselineEntry: baselineEntry,
            changeFromBaselineKg: changeFromBaselineKg,
            loggingWindowDays: loggingWindowDays,
            averageFastingHoursDuringWindow: averageFastingHoursDuringWindow
        )
    }

    static func recentPoints(
        weightEntries: [WeightEntry],
        limit: Int = 7
    ) -> [WeightTrendPoint] {
        weightEntries
            .sorted { $0.recordedAt < $1.recordedAt }
            .suffix(limit)
            .map {
                WeightTrendPoint(
                    id: $0.id,
                    date: $0.recordedAt,
                    weightKg: $0.weightKg
                )
            }
    }

    private static func averageFastingSeconds(
        in interval: DateInterval,
        records: [FastingRecord],
        now: Date,
        calendar: Calendar
    ) -> Int? {
        guard interval.end > interval.start else { return nil }

        let dayMetrics = FastingAnalytics.dayMetricsByDate(records: records, now: now, calendar: calendar)
        let startDay = calendar.startOfDay(for: interval.start)
        let endDay = calendar.startOfDay(for: calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end)
        let dayCount = max(
            1,
            calendar.dateComponents([.day], from: startDay, to: endDay).day.map { $0 + 1 } ?? 1
        )

        let totalSeconds = stride(from: 0, to: dayCount, by: 1).reduce(0) { partialResult, offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startDay) ?? startDay
            return partialResult + (dayMetrics[day]?.fastingSeconds ?? 0)
        }

        return totalSeconds / dayCount
    }
}
