import Foundation

struct FastingDayMetrics {
    let date: Date
    var fastingSeconds: Int = 0
    var completedGoalSessions: Int = 0
    var completedSessions: Int = 0
    var abortedSessions: Int = 0
    var ongoingSessions: Int = 0

    var hasGoalMet: Bool {
        completedGoalSessions > 0
    }

    var hasAbortedSession: Bool {
        abortedSessions > 0
    }
}

struct FastingStartSample: Identifiable {
    let id: Date
    let day: Date
    let startAt: Date
    let minutesFromMidnight: Int
}

struct FastingStartConsistency {
    let samples: [FastingStartSample]
    let typicalStartMinute: Int?
    let averageDriftMinutes: Int?

    var rhythmLabel: String {
        guard let averageDriftMinutes else { return AppL10n.string("stats.rhythm.no_data") }
        switch averageDriftMinutes {
        case ..<30:
            return AppL10n.string("stats.rhythm.very_steady")
        case ..<60:
            return AppL10n.string("stats.rhythm.steady")
        case ..<120:
            return AppL10n.string("stats.rhythm.flexible")
        default:
            return AppL10n.string("stats.rhythm.irregular")
        }
    }
}

enum FastingWeeklyFocus {
    case keepRhythm
    case stabilizeStartTime
    case improveCompletion
    case gentlerPlan
    case buildHabit
}

struct FastingWeeklyReport {
    let interval: DateInterval
    let totalFastingSeconds: Int
    let activeDays: Int
    let completedGoalDays: Int
    let completedSessions: Int
    let abortedSessions: Int
    let averageDailyHours: Double
    let bestDay: Date?
    let bestDayHours: Double
    let startConsistency: FastingStartConsistency
    let headline: String
    let summary: String
    let highlights: [String]
    let focus: FastingWeeklyFocus
}

enum FastingAnalytics {
    static func dayMetricsByDate(
        records: [FastingRecord],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [Date: FastingDayMetrics] {
        var metricsByDay: [Date: FastingDayMetrics] = [:]

        for record in records {
            guard let sessionEnd = effectiveSessionEnd(for: record, now: now) else {
                continue
            }

            accumulateFastingSeconds(
                from: record.startAt,
                to: sessionEnd,
                calendar: calendar,
                into: &metricsByDay
            )

            switch record.status {
            case FastingRecordStatus.completed:
                guard let endAt = record.endAt else { continue }
                incrementOutcome(on: endAt, calendar: calendar, metricsByDay: &metricsByDay) { metrics in
                    metrics.completedSessions += 1
                    if record.isGoalMet {
                        metrics.completedGoalSessions += 1
                    }
                }
            case FastingRecordStatus.notCompleted, FastingRecordStatus.legacyAborted:
                guard let endAt = record.endAt else { continue }
                incrementOutcome(on: endAt, calendar: calendar, metricsByDay: &metricsByDay) { metrics in
                    metrics.abortedSessions += 1
                }
            case FastingRecordStatus.ongoing:
                incrementOutcome(on: now, calendar: calendar, metricsByDay: &metricsByDay) { metrics in
                    metrics.ongoingSessions += 1
                }
            default:
                continue
            }
        }

        return metricsByDay
    }

    static func goalCompletionDayCount(
        in interval: DateInterval,
        records: [FastingRecord],
        calendar: Calendar = .current
    ) -> Int {
        goalCompletionDates(records: records, calendar: calendar)
            .filter { $0 >= interval.start && $0 < interval.end }
            .count
    }

    static func bestGoalStreak(
        records: [FastingRecord],
        calendar: Calendar = .current
    ) -> Int {
        let days = goalCompletionDates(records: records, calendar: calendar).sorted()
        guard !days.isEmpty else { return 0 }

        var best = 0
        var current = 0
        var previousDay: Date?

        for day in days {
            if let previousDay,
               let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(nextDay, inSameDayAs: day) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previousDay = day
        }

        return best
    }

    static func goalCompletionDates(
        records: [FastingRecord],
        calendar: Calendar = .current
    ) -> [Date] {
        let uniqueDays = Set<Date>(
            records.compactMap { record in
                guard FastingRecordStatus.isCompleted(record.status),
                      record.isGoalMet,
                      let endAt = record.endAt else {
                    return nil
                }
                return calendar.startOfDay(for: endAt)
            }
        )

        return Array(uniqueDays)
    }

    static func effectiveSessionEnd(for record: FastingRecord, now: Date = Date()) -> Date? {
        switch record.status {
        case FastingRecordStatus.completed, FastingRecordStatus.notCompleted, FastingRecordStatus.legacyAborted:
            return record.endAt
        case FastingRecordStatus.ongoing:
            return now
        default:
            return record.endAt
        }
    }

    static func startConsistency(
        records: [FastingRecord],
        now: Date = Date(),
        calendar: Calendar = .current,
        limit: Int = 7
    ) -> FastingStartConsistency {
        let samples = primaryStartSamples(
            records: records,
            now: now,
            calendar: calendar,
            limit: limit
        )

        let minutes = samples.map(\.minutesFromMidnight)
        guard let typicalStartMinute = circularMeanMinute(minutes) else {
            return FastingStartConsistency(
                samples: samples,
                typicalStartMinute: nil,
                averageDriftMinutes: nil
            )
        }

        let driftValues = minutes.map { circularDistanceInMinutes($0, typicalStartMinute) }
        let averageDrift = driftValues.isEmpty ? nil : driftValues.reduce(0, +) / driftValues.count

        return FastingStartConsistency(
            samples: samples,
            typicalStartMinute: typicalStartMinute,
            averageDriftMinutes: averageDrift
        )
    }

    static func weeklyReport(
        records: [FastingRecord],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FastingWeeklyReport {
        let interval = recentSevenDayInterval(now: now, calendar: calendar)
        let dayMetrics = dayMetricsByDate(records: records, now: now, calendar: calendar)
        let reportDays = recentSevenDays(now: now, calendar: calendar)
        let metrics = reportDays.map { day in
            dayMetrics[day] ?? FastingDayMetrics(date: day)
        }

        let totalFastingSeconds = metrics.reduce(0) { $0 + $1.fastingSeconds }
        let activeDays = metrics.filter { $0.fastingSeconds > 0 }.count
        let completedGoalDays = metrics.filter { $0.hasGoalMet }.count
        let completedSessions = metrics.reduce(0) { $0 + $1.completedSessions }
        let abortedSessions = metrics.reduce(0) { $0 + $1.abortedSessions }
        let averageDailyHours = Double(totalFastingSeconds) / 3600.0 / 7.0

        let bestMetric = metrics.max { $0.fastingSeconds < $1.fastingSeconds }
        let bestDay = bestMetric?.fastingSeconds ?? 0 > 0 ? bestMetric?.date : nil
        let bestDayHours = Double(bestMetric?.fastingSeconds ?? 0) / 3600.0
        let consistency = startConsistency(records: records, now: now, calendar: calendar, limit: 7)

        let focus = weeklyFocus(
            activeDays: activeDays,
            completedGoalDays: completedGoalDays,
            completedSessions: completedSessions,
            abortedSessions: abortedSessions,
            rhythmLabel: consistency.rhythmLabel
        )

        let headline = weeklyHeadline(
            activeDays: activeDays,
            completedGoalDays: completedGoalDays,
            rhythmLabel: consistency.rhythmLabel
        )

        let summary = weeklySummary(
            activeDays: activeDays,
            completedGoalDays: completedGoalDays,
            averageDailyHours: averageDailyHours,
            consistency: consistency
        )

        let highlights = weeklyHighlights(
            interval: interval,
            totalFastingSeconds: totalFastingSeconds,
            activeDays: activeDays,
            completedGoalDays: completedGoalDays,
            bestDay: bestDay,
            bestDayHours: bestDayHours,
            startConsistency: consistency,
            calendar: calendar
        )

        return FastingWeeklyReport(
            interval: interval,
            totalFastingSeconds: totalFastingSeconds,
            activeDays: activeDays,
            completedGoalDays: completedGoalDays,
            completedSessions: completedSessions,
            abortedSessions: abortedSessions,
            averageDailyHours: averageDailyHours,
            bestDay: bestDay,
            bestDayHours: bestDayHours,
            startConsistency: consistency,
            headline: headline,
            summary: summary,
            highlights: highlights,
            focus: focus
        )
    }

    private static func accumulateFastingSeconds(
        from start: Date,
        to end: Date,
        calendar: Calendar,
        into metricsByDay: inout [Date: FastingDayMetrics]
    ) {
        guard end > start else { return }

        var cursor = start
        while cursor < end {
            let dayStart = calendar.startOfDay(for: cursor)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                break
            }
            let segmentEnd = min(end, nextDay)
            let seconds = max(0, Int(segmentEnd.timeIntervalSince(cursor)))

            updateMetrics(on: dayStart, calendar: calendar, metricsByDay: &metricsByDay) { metrics in
                metrics.fastingSeconds += seconds
            }

            cursor = segmentEnd
        }
    }

    private static func incrementOutcome(
        on date: Date,
        calendar: Calendar,
        metricsByDay: inout [Date: FastingDayMetrics],
        update: (inout FastingDayMetrics) -> Void
    ) {
        updateMetrics(on: date, calendar: calendar, metricsByDay: &metricsByDay, update: update)
    }

    private static func updateMetrics(
        on date: Date,
        calendar: Calendar,
        metricsByDay: inout [Date: FastingDayMetrics],
        update: (inout FastingDayMetrics) -> Void
    ) {
        let day = calendar.startOfDay(for: date)
        var metrics = metricsByDay[day] ?? FastingDayMetrics(date: day)
        update(&metrics)
        metricsByDay[day] = metrics
    }

    private static func primaryStartSamples(
        records: [FastingRecord],
        now: Date,
        calendar: Calendar,
        limit: Int
    ) -> [FastingStartSample] {
        var primaryRecordByDay: [Date: FastingRecord] = [:]

        for record in records {
            let day = calendar.startOfDay(for: record.startAt)
            guard let duration = sessionDurationSeconds(for: record, now: now) else {
                continue
            }

            if let existing = primaryRecordByDay[day],
               let existingDuration = sessionDurationSeconds(for: existing, now: now),
               existingDuration >= duration {
                continue
            }

            primaryRecordByDay[day] = record
        }

        return primaryRecordByDay
            .sorted { $0.key < $1.key }
            .suffix(limit)
            .map { day, record in
                let components = calendar.dateComponents([.hour, .minute], from: record.startAt)
                let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                return FastingStartSample(
                    id: day,
                    day: day,
                    startAt: record.startAt,
                    minutesFromMidnight: minutes
                )
            }
    }

    private static func sessionDurationSeconds(for record: FastingRecord, now: Date) -> Int? {
        guard let end = effectiveSessionEnd(for: record, now: now) else { return nil }
        return max(0, Int(end.timeIntervalSince(record.startAt)))
    }

    private static func circularMeanMinute(_ minutes: [Int]) -> Int? {
        guard !minutes.isEmpty else { return nil }

        let angles = minutes.map { Double($0) / 1440.0 * 2.0 * Double.pi }
        let x = angles.reduce(0.0) { $0 + cos($1) }
        let y = angles.reduce(0.0) { $0 + sin($1) }
        guard x != 0 || y != 0 else { return nil }

        var meanAngle = atan2(y, x)
        if meanAngle < 0 {
            meanAngle += 2.0 * Double.pi
        }

        let minute = Int(round(meanAngle / (2.0 * Double.pi) * 1440.0)) % 1440
        return minute
    }

    private static func circularDistanceInMinutes(_ lhs: Int, _ rhs: Int) -> Int {
        let diff = abs(lhs - rhs)
        return min(diff, 1440 - diff)
    }

    private static func recentSevenDayInterval(now: Date, calendar: Calendar) -> DateInterval {
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        return DateInterval(start: start, end: end)
    }

    private static func recentSevenDays(now: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }
    }

    private static func weeklyFocus(
        activeDays: Int,
        completedGoalDays: Int,
        completedSessions: Int,
        abortedSessions: Int,
        rhythmLabel: String
    ) -> FastingWeeklyFocus {
        if activeDays == 0 {
            return .buildHabit
        }
        if abortedSessions > completedSessions {
            return .gentlerPlan
        }
        if rhythmLabel == AppL10n.string("stats.rhythm.irregular") || rhythmLabel == AppL10n.string("stats.rhythm.flexible") {
            return .stabilizeStartTime
        }
        if completedGoalDays < 4 {
            return .improveCompletion
        }
        return .keepRhythm
    }

    private static func weeklyHeadline(
        activeDays: Int,
        completedGoalDays: Int,
        rhythmLabel: String
    ) -> String {
        if activeDays == 0 {
            return AppL10n.string("weekly.headline.no_rhythm")
        }
        if completedGoalDays >= 5 && (
            rhythmLabel == AppL10n.string("stats.rhythm.very_steady") ||
            rhythmLabel == AppL10n.string("stats.rhythm.steady")
        ) {
            return AppL10n.string("weekly.headline.steady")
        }
        if completedGoalDays >= 3 {
            return AppL10n.string("weekly.headline.foundation")
        }
        if rhythmLabel == AppL10n.string("stats.rhythm.irregular") {
            return AppL10n.string("weekly.headline.not_longer")
        }
        return AppL10n.string("weekly.headline.habit")
    }

    private static func weeklySummary(
        activeDays: Int,
        completedGoalDays: Int,
        averageDailyHours: Double,
        consistency: FastingStartConsistency
    ) -> String {
        guard activeDays > 0 else {
            return AppL10n.string("weekly.summary.empty")
        }

        if let typicalStartMinute = consistency.typicalStartMinute {
            return AppL10n.format(
                "weekly.summary.with_time",
                activeDays,
                completedGoalDays,
                String(format: "%.1f", averageDailyHours),
                formattedTime(fromMinutes: typicalStartMinute)
            )
        }

        return AppL10n.format(
            "weekly.summary.without_time",
            activeDays,
            completedGoalDays,
            String(format: "%.1f", averageDailyHours)
        )
    }

    private static func weeklyHighlights(
        interval: DateInterval,
        totalFastingSeconds: Int,
        activeDays: Int,
        completedGoalDays: Int,
        bestDay: Date?,
        bestDayHours: Double,
        startConsistency: FastingStartConsistency,
        calendar: Calendar
    ) -> [String] {
        var items: [String] = []

        items.append(
            AppL10n.format(
                "weekly.highlight.total_hours",
                String(format: "%.1f", Double(totalFastingSeconds) / 3600.0),
                activeDays
            )
        )
        items.append(AppL10n.format("weekly.highlight.completed_days", completedGoalDays))

        if let bestDay {
            let formatter = AppL10n.formatter(dateFormat: "EEE")
            items.append(
                AppL10n.format(
                    "weekly.highlight.best_day",
                    formatter.string(from: bestDay),
                    String(format: "%.1f", bestDayHours)
                )
            )
        }

        if let typicalStartMinute = startConsistency.typicalStartMinute,
           let drift = startConsistency.averageDriftMinutes {
            items.append(
                AppL10n.format(
                    "weekly.highlight.typical_start",
                    formattedTime(fromMinutes: typicalStartMinute),
                    drift
                )
            )
        }

        return items
    }

    private static func formattedTime(fromMinutes minutes: Int) -> String {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = AppL10n.formatter(dateFormat: "HH:mm")
        return formatter.string(from: date)
    }
}
