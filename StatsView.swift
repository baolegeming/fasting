import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject private var viewModel: FastFlowTimerViewModel
    @EnvironmentObject private var weightStore: WeightStore
    @EnvironmentObject private var subscriptionRuntime: SubscriptionRuntime
    @Query(sort: \FastingRecord.startAt, order: .reverse) private var records: [FastingRecord]
    @AppStorage(FastFlowDefaultsKey.isPro) private var isPro = false
    @AppStorage(FastFlowDefaultsKey.adInventoryMode) private var adInventoryModeRaw = AdInventoryMode.buildFallbackDefault.rawValue
    @State private var showPaywall = false
    @State private var showWeeklyReport = false
    @State private var showWeightEntrySheet = false
    @State private var showWeightRecordsSheet = false

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "121212")
    private let cardDark = Color(hex: "1C1C1E")

    private var dayMetrics: [Date: FastingDayMetrics] {
        FastingAnalytics.dayMetricsByDate(records: records)
    }

    private var startConsistency: FastingStartConsistency {
        FastingAnalytics.startConsistency(records: records)
    }

    private var weeklyReport: FastingWeeklyReport {
        FastingAnalytics.weeklyReport(records: records)
    }

    private var weightSummary: WeightTrendSummary {
        WeightAnalytics.summary(weightEntries: weightStore.entries, fastingRecords: records)
    }

    private var weightTrendPoints: [WeightTrendPoint] {
        WeightAnalytics.recentPoints(weightEntries: weightStore.entries)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        durationCard
                        completionCard
                        startConsistencyCard
                        weeklyReportCard
                        weightCard
                        if let adPresentation = insightsAdPresentation {
                            NativeAdSlotView(presentation: adPresentation) {
                                showPaywall = true
                            }
                        }
                        if !effectiveIsPro {
                            proLockedCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(AppL10n.string("stats.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showWeeklyReport) {
                WeeklyReportSheetView(report: weeklyReport)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showWeightEntrySheet) {
                WeightEntrySheetView(
                    initialWeightKg: weightSummary.latestEntry?.weightKg,
                    onSave: { weightKg, recordedAt in
                        weightStore.addEntry(weightKg: weightKg, recordedAt: recordedAt)
                        showWeightEntrySheet = false
                    },
                    onCancel: {
                        showWeightEntrySheet = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showWeightRecordsSheet) {
                WeightEntriesSheetView()
            }
        }
    }

    private var durationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppL10n.string("stats.daily_hours.title"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
                Text(averageDailyHoursText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text(AppL10n.string("stats.daily_hours.subtitle"))
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            Chart {
                ForEach(trendPoints) { point in
                    BarMark(
                        x: .value("Day", point.date),
                        y: .value("Hours", point.hours)
                    )
                    .foregroundStyle(primary.gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: trendPoints.map(\.date)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(weekdayLabel(for: date))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.system(size: 10))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                compactMetric(title: AppL10n.string("stats.daily_hours.total"), value: totalDailyHoursText)
                compactMetric(title: AppL10n.string("stats.daily_hours.active_days"), value: "\(activeFastingDayCount)/7")
            }
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var completionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppL10n.string("stats.completion.title"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
                Text(AppL10n.string("stats.completion.subtitle"))
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 10) {
                compactMetric(title: AppL10n.string("stats.completion.this_week"), value: "\(thisWeekGoalCount)/7")
                compactMetric(title: AppL10n.string("stats.completion.best_streak"), value: "\(bestStreak)d")
                compactMetric(title: AppL10n.string("stats.completion.completed"), value: "\(recentCompletedSessionCount)")
            }

            HStack(spacing: 8) {
                ForEach(recentSevenDays, id: \.self) { day in
                    let state = completionState(for: day)
                    VStack(spacing: 8) {
                        Text(weekdayLetter(for: day))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray)
                        Circle()
                            .fill(completionColor(for: state))
                            .frame(width: 12, height: 12)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text(AppL10n.string("stats.completion.legend"))
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var startConsistencyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppL10n.string("stats.start_consistency.title"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
                Text(AppL10n.string("stats.start_consistency.subtitle"))
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 10) {
                compactMetric(title: AppL10n.string("stats.start_consistency.typical_start"), value: typicalStartText)
                compactMetric(title: AppL10n.string("stats.start_consistency.avg_drift"), value: averageDriftText)
                compactMetric(
                    title: AppL10n.string("stats.start_consistency.rhythm"),
                    value: startConsistency.rhythmLabel,
                    valueColor: rhythmColor(for: startConsistency.rhythmLabel)
                )
            }

            if startConsistency.samples.isEmpty {
                Text(AppL10n.string("stats.start_consistency.empty"))
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
            } else {
                HStack(spacing: 8) {
                    ForEach(startConsistency.samples) { sample in
                        VStack(spacing: 8) {
                            Text(shortWeekdayLabel(for: sample.day))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.gray)
                            Text(timeText(fromMinutes: sample.minutesFromMidnight))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var weeklyReportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppL10n.string("weekly.report.title"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray)
                    Text(weeklyReport.headline)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button(AppL10n.string("common.open")) {
                    showWeeklyReport = true
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(primary)
            }

            Text(weeklyReport.summary)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .lineSpacing(3)

            HStack(spacing: 10) {
                compactMetric(title: AppL10n.string("Goal Days"), value: "\(weeklyReport.completedGoalDays)/7")
                compactMetric(title: AppL10n.string("Total Hours"), value: totalWeeklyReportHoursText)
                compactMetric(title: AppL10n.string("stats.weekly_report.focus"), value: weeklyFocusShortLabel)
            }
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppL10n.string("Weight Log"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray)
                    Text(weightHeadlineText)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    showWeightEntrySheet = true
                } label: {
                    Text(weightStore.entries.isEmpty ? AppL10n.string("weight.add_first") : AppL10n.string("weight.add_entry"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(primary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Text(weightSummaryText)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .lineSpacing(3)

            if weightStore.entries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                        Text(AppL10n.string("weight.empty.tip"))
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    Button {
                        showWeightEntrySheet = true
                    } label: {
                        Text(AppL10n.string("Log Weight"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(primary, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(14)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
            } else {
                Chart {
                    ForEach(weightTrendPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weightKg)
                        )
                        .foregroundStyle(primary.gradient)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weightKg)
                        )
                        .foregroundStyle(.white)
                    }
                }
                .frame(height: 170)
                .chartXAxis {
                    AxisMarks(values: weightTrendPoints.map(\.date)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(shortMonthDayLabel(for: date))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text(String(format: "%.1f", weight))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    compactMetric(title: AppL10n.string("weight.entries"), value: "\(weightStore.entries.count)")
                    compactMetric(title: AppL10n.string("weight.window"), value: "\(weightSummary.loggingWindowDays)d")
                    compactMetric(title: AppL10n.string("weight.fasting_avg"), value: averageWindowFastingText)
                }

                Button {
                    showWeightRecordsSheet = true
                } label: {
                    HStack {
                        Text(AppL10n.string("Manage weight records"))
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }

                Text(AppL10n.string("weight.disclaimer"))
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func compactMetric(title: String, value: String, valueColor: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.gray)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var proLockedCard: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(AppL10n.string("Advanced Pro Tools"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 140)
            }
            .padding(16)
            .blur(radius: 2)
            .opacity(0.45)

            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(primary)
                    .padding(12)
                    .background(primary.opacity(0.2), in: Circle())
                Text(AppL10n.string("More Pro Features Ahead"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text(AppL10n.string("pro.locked.body"))
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
                Button(AppL10n.string("pro.locked.cta")) {
                    showPaywall = true
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.vertical, 20)
        }
        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var insightsAdPresentation: NativeAdPresentation? {
        MonetizationPolicy.nativePlacement(
            for: .insightsNative,
            isPro: effectiveIsPro,
            rawAdMode: adInventoryModeRaw
        )
    }

    private var effectiveIsPro: Bool {
        subscriptionRuntime.isProActive || isPro
    }

    private var thisWeekGoalCount: Int {
        let cal = Calendar.current
        let now = Date()
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return FastingAnalytics.goalCompletionDayCount(
            in: weekInterval,
            records: records,
            calendar: cal
        )
    }

    private var bestStreak: Int {
        FastingAnalytics.bestGoalStreak(records: records)
    }

    private var recentCompletedSessionCount: Int {
        let recentStart = recentSevenDays.first ?? Calendar.current.startOfDay(for: Date())
        return records.filter {
            $0.status == "completed" &&
            ($0.endAt.map { $0 >= recentStart } ?? false)
        }.count
    }

    private var averageDailyHoursText: String {
        let avg = trendPoints.reduce(0.0) { $0 + $1.hours } / Double(max(trendPoints.count, 1))
        return AppL10n.format("stats.hours_per_day.format", String(format: "%.1f", avg))
    }

    private var totalDailyHoursText: String {
        let totalHours = trendPoints.reduce(0.0) { $0 + $1.hours }
        return AppL10n.format("weekly.share.hours", String(format: "%.1f", totalHours))
    }

    private var activeFastingDayCount: Int {
        trendPoints.filter { $0.hours > 0 }.count
    }

    private var typicalStartText: String {
        guard let typicalMinute = startConsistency.typicalStartMinute else { return "--" }
        return timeText(fromMinutes: typicalMinute)
    }

    private var averageDriftText: String {
        guard let drift = startConsistency.averageDriftMinutes else { return "--" }
        return AppL10n.format("stats.avg_drift.format", drift)
    }

    private var totalWeeklyReportHoursText: String {
        AppL10n.format("weekly.share.hours", String(format: "%.1f", Double(weeklyReport.totalFastingSeconds) / 3600.0))
    }

    private var weightHeadlineText: String {
        guard let latestEntry = weightSummary.latestEntry else { return AppL10n.string("weight.none") }
        return AppL10n.format("weight.value.kg", String(format: "%.1f", latestEntry.weightKg))
    }

    private var weightSummaryText: String {
        guard let latestEntry = weightSummary.latestEntry else {
            return AppL10n.string("weight.summary.empty")
        }

        let sourceText = latestEntry.source.label
        let loggedAtText = shortDateTimeLabel(for: latestEntry.recordedAt)

        if let change = weightSummary.changeFromBaselineKg,
           let baselineEntry = weightSummary.baselineEntry {
            let sign = change > 0 ? "+" : ""
            return AppL10n.format(
                "weight.summary.with_change",
                loggedAtText,
                sourceText,
                shortMonthDayLabel(for: baselineEntry.recordedAt),
                "\(sign)\(String(format: "%.1f", change))"
            )
        }

        return AppL10n.format("weight.summary.baseline", loggedAtText, sourceText)
    }

    private var averageWindowFastingText: String {
        guard let average = weightSummary.averageFastingHoursDuringWindow else { return "--" }
        return AppL10n.format("stats.hours_per_day.format", String(format: "%.1f", average))
    }

    private var weeklyFocusShortLabel: String {
        switch weeklyReport.focus {
        case .keepRhythm:
            return AppL10n.string("weekly.focus.short.keep")
        case .stabilizeStartTime:
            return AppL10n.string("weekly.focus.short.steady")
        case .improveCompletion:
            return AppL10n.string("weekly.focus.short.finish")
        case .gentlerPlan:
            return AppL10n.string("weekly.focus.short.adjust")
        case .buildHabit:
            return AppL10n.string("weekly.focus.short.start")
        }
    }

    private struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let hours: Double
    }

    private var trendPoints: [TrendPoint] {
        recentSevenDays.map { day in
            let sec = dayMetrics[Calendar.current.startOfDay(for: day)]?.fastingSeconds ?? 0
            return TrendPoint(date: day, hours: Double(sec) / 3600.0)
        }
    }

    private var recentSevenDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -6 + $0, to: today) }
    }

    private enum CompletionState {
        case goalMet
        case aborted
        case ongoing
        case empty
    }

    private func completionState(for day: Date) -> CompletionState {
        let dayStart = Calendar.current.startOfDay(for: day)
        guard let metrics = dayMetrics[dayStart] else { return .empty }
        if metrics.hasGoalMet { return .goalMet }
        if metrics.hasAbortedSession { return .aborted }
        if metrics.ongoingSessions > 0 { return .ongoing }
        return .empty
    }

    private func completionColor(for state: CompletionState) -> Color {
        switch state {
        case .goalMet:
            return .green
        case .aborted:
            return .red
        case .ongoing:
            return primary
        case .empty:
            return Color.white.opacity(0.16)
        }
    }

    private func rhythmColor(for label: String) -> Color {
        switch label {
        case AppL10n.string("stats.rhythm.very_steady"):
            return .green
        case AppL10n.string("stats.rhythm.steady"):
            return primary
        case AppL10n.string("stats.rhythm.flexible"):
            return .yellow
        case AppL10n.string("stats.rhythm.irregular"):
            return .red
        default:
            return .gray
        }
    }

    private func weekdayLabel(for date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "EEE")
        return formatter.string(from: date).uppercased()
    }

    private func weekdayLetter(for date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "EEEEE")
        return formatter.string(from: date).uppercased()
    }

    private func shortWeekdayLabel(for date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "EEE")
        return formatter.string(from: date)
    }

    private func shortMonthDayLabel(for date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "MM/dd")
        return formatter.string(from: date)
    }

    private func shortDateTimeLabel(for date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "MM/dd HH:mm")
        return formatter.string(from: date)
    }

    private func timeText(fromMinutes minutes: Int) -> String {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = AppL10n.formatter(dateFormat: "HH:mm")
        return formatter.string(from: date)
    }
}

#Preview {
    StatsView()
        .environmentObject(FastFlowTimerViewModel())
        .environmentObject(WeightStore())
        .modelContainer(for: [FastingRecord.self, DailySummary.self], inMemory: true)
        .preferredColorScheme(.dark)
}
