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
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showWeeklyReport) {
                WeeklyReportSheetView(report: weeklyReport)
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
                Text("Daily Fasting Hours")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
                Text(averageDailyHoursText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("最近 7 天按自然日拆分统计，用来看每天实际处于空腹状态的时长。")
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
                compactMetric(title: "7-Day Total", value: totalDailyHoursText)
                compactMetric(title: "Active Days", value: "\(activeFastingDayCount)/7")
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
                Text("Completion Summary")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
                Text("完成类指标按断食结束日期统计")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 10) {
                compactMetric(title: "This Week", value: "\(thisWeekGoalCount)/7")
                compactMetric(title: "Best Streak", value: "\(bestStreak)d")
                compactMetric(title: "Completed", value: "\(recentCompletedSessionCount)")
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

            Text("绿色表示当天完成过目标，红色表示当天有中断记录，橙色表示今天仍有进行中的断食。")
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
                Text("Start Time Consistency")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
                Text("基于每天持续时间最长的那次断食开始时间统计。")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 10) {
                compactMetric(title: "Typical Start", value: typicalStartText)
                compactMetric(title: "Avg Drift", value: averageDriftText)
                compactMetric(
                    title: "Rhythm",
                    value: startConsistency.rhythmLabel,
                    valueColor: rhythmColor(for: startConsistency.rhythmLabel)
                )
            }

            if startConsistency.samples.isEmpty {
                Text("开始几次断食后，这里会显示你的开始时间节奏。")
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
                    Text("Weekly Report")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray)
                    Text(weeklyReport.headline)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button("Open") {
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
                compactMetric(title: "Goal Days", value: "\(weeklyReport.completedGoalDays)/7")
                compactMetric(title: "Total Hours", value: totalWeeklyReportHoursText)
                compactMetric(title: "Focus", value: weeklyFocusShortLabel)
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
                    Text("Weight Log")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray)
                    Text(weightHeadlineText)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button(weightStore.entries.isEmpty ? "Add First" : "Add Entry") {
                    showWeightEntrySheet = true
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(primary)
            }

            Text(weightSummaryText)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .lineSpacing(3)

            if weightStore.entries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("先从第一条体重开始，后面我们会把体重趋势和断食节奏放在同一张卡里一起看。")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    Button("Log Weight") {
                        showWeightEntrySheet = true
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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
                    compactMetric(title: "Entries", value: "\(weightStore.entries.count)")
                    compactMetric(title: "Window", value: "\(weightSummary.loggingWindowDays)d")
                    compactMetric(title: "Fasting Avg", value: averageWindowFastingText)
                }

                Button {
                    showWeightRecordsSheet = true
                } label: {
                    HStack {
                        Text("Manage weight records")
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

                Text("这里展示的是同期观察，不代表体重变化完全由断食造成。")
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

    private func compactMetric(title: LocalizedStringKey, value: String, valueColor: Color = .white) -> some View {
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
                Text("Advanced Pro Tools")
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
                Text("More Pro Features Ahead")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("高级历史筛选、去广告和更深层洞察会继续进入 Pro。")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
                Button("See Pro") {
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
