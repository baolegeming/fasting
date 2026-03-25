import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: FastFlowTimerViewModel
    @EnvironmentObject private var subscriptionRuntime: SubscriptionRuntime
    @Query(sort: \FastingRecord.startAt, order: .reverse) private var allRecords: [FastingRecord]
    @AppStorage(FastFlowDefaultsKey.isPro) private var isPro = false
    @AppStorage(FastFlowDefaultsKey.adInventoryMode) private var adInventoryModeRaw = AdInventoryMode.buildFallbackDefault.rawValue
    @State private var showPaywall = false
    @State private var showAddRecordSheet = false
    @State private var showFilterSheet = false
    @State private var editingRecord: FastingRecord?
    @State private var deletingRecord: FastingRecord?
    @State private var historyFilter = HistoryAdvancedFilter()

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "221610")
    private let cardBorder = Color.white.opacity(0.10)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        sevenDayCalendarStrip
                        todayCard
                        recordsSection
                        if let adPresentation = historyAdPresentation {
                            NativeAdSlotView(presentation: adPresentation) {
                                showPaywall = true
                            }
                        }
                        historyFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        if effectiveIsPro {
                            showFilterSheet = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: effectiveFilter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(effectiveIsPro ? (effectiveFilter.isActive ? primary : .gray) : primary)
                    }

                    Button {
                        showAddRecordSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(primary)
                    }
                }
            }
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showFilterSheet) {
                HistoryFilterSheetView(filter: $historyFilter)
            }
            .sheet(isPresented: $showAddRecordSheet) {
                FastingRecordEditorSheetView(
                    initialPlanType: viewModel.targetPlanType,
                    initialTargetDurationSec: viewModel.targetDurationSec,
                    initialStartAt: defaultAddStartAt,
                    initialEndAt: defaultAddEndAt,
                    onSave: { draft in
                        insertRecord(draft)
                        showAddRecordSheet = false
                    },
                    onCancel: {
                        showAddRecordSheet = false
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: Binding(
                get: { editingRecord != nil },
                set: { if !$0 { editingRecord = nil } }
            )) {
                if let editingRecord {
                    FastingRecordEditorSheetView(
                        record: editingRecord,
                        onSave: { draft in
                            applyEdit(draft, to: editingRecord)
                            self.editingRecord = nil
                        },
                        onDelete: {
                            deleteRecord(editingRecord)
                            self.editingRecord = nil
                        },
                        onCancel: {
                            self.editingRecord = nil
                        }
                    )
                    .presentationDetents([.large])
                }
            }
        }
    }

    private var sevenDayCalendarStrip: some View {
        let days = recentSevenDays
        return HStack(spacing: 8) {
            ForEach(days, id: \.self) { day in
                let state = stateForDay(day)
                let isToday = Calendar.current.isDateInToday(day)
                VStack(spacing: 8) {
                    Text(weekdayShort(day))
                        .font(.system(size: 11, weight: isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? primary : .gray)
                    ZStack {
                        Circle()
                            .fill(fillColor(for: state, isToday: isToday))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isToday ? primary : borderColor(for: state),
                                        lineWidth: isToday ? 2 : 1
                                    )
                            )
                        Text(dayNumber(day))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(numberColor(for: state, isToday: isToday))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Fasting")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    Text(todayPlanName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text(todayBadgeText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(todayBadgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(todayBadgeColor.opacity(0.15), in: Capsule())
            }

            if hasOngoingSession {
                HStack(spacing: 12) {
                    metricTile(title: "Elapsed", value: formattedElapsedForHistory, emphasize: false)
                    metricTile(title: "Remaining", value: formattedRemainingForHistory, emphasize: true)
                }
            } else {
                Text(todayStatusDescription)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.gray)
            }
        }
        .padding(18)
        .background(Color.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(cardBorder, lineWidth: 1)
        )
    }

    private func metricTile(title: LocalizedStringKey, value: String, emphasize: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.gray)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(emphasize ? primary : .white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(primary.opacity(0.15), lineWidth: 1)
        )
    }

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(primary)
                    Text("All Records")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text(recordsCountText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.gray)
            }

            if effectiveFilter.isActive {
                filterSummary
            }

            if displayedRecords.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    if allRecords.isEmpty {
                        Text("还没有断食记录。你可以开始一次新的计时，也可以先补录之前完成过的 session。")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("补录断食记录") {
                            showAddRecordSheet = true
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(primary, in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("当前筛选条件下没有匹配的记录。你可以调整筛选条件，或清除后查看全部历史。")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("清除筛选") {
                            historyFilter = HistoryAdvancedFilter()
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(primary, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cardBorder, lineWidth: 1)
                )
            } else {
                ForEach(displayedRecords, id: \.id) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionRangeText(for: record))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("\(planName(for: record)) · \(durationText(for: record))")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Text(statusBadgeText(for: record))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(statusBadgeColor(for: record))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(statusBadgeColor(for: record).opacity(0.15), in: Capsule())

                            if isEditable(record) {
                                Menu {
                                    Button("Edit") {
                                        editingRecord = record
                                    }
                                    Button("Delete", role: .destructive) {
                                        deletingRecord = record
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.gray)
                                        .frame(width: 28, height: 28)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(cardBorder, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var historyFooter: some View {
        HStack(spacing: 4) {
            Text(
                effectiveIsPro
                ? AppL10n.string("你已解锁 History Pro 筛选，可按时间、计划、状态和中断原因快速回看记录。")
                : AppL10n.string("完整历史当前对所有用户开放。免费版会在 History 保留一个原生广告位，Pro 会移除广告并保留高级筛选。")
            )
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            if !effectiveIsPro {
                Button("升级") {
                    showPaywall = true
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(primary)
            }
        }
        .padding(.vertical, 6)
        .alert(
            "删除这条断食记录？",
            isPresented: Binding(
                get: { deletingRecord != nil },
                set: { if !$0 { deletingRecord = nil } }
            ),
            actions: {
                Button("删除", role: .destructive) {
                    if let deletingRecord {
                        deleteRecord(deletingRecord)
                    }
                    deletingRecord = nil
                }
                Button("取消", role: .cancel) {
                    deletingRecord = nil
                }
            },
            message: {
                Text("删除后，相关统计和周报会按剩余记录立即重算。")
            }
        )
    }

    private var recentSevenDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            cal.date(byAdding: .day, value: -6 + offset, to: today)
        }
    }

    private var displayedRecords: [FastingRecord] {
        allRecords.filter { effectiveFilter.matches($0) }
    }

    private var effectiveFilter: HistoryAdvancedFilter {
        effectiveIsPro ? historyFilter : HistoryAdvancedFilter()
    }

    private var historyAdPresentation: NativeAdPresentation? {
        MonetizationPolicy.nativePlacement(
            for: .historyNative,
            isPro: effectiveIsPro,
            rawAdMode: adInventoryModeRaw
        )
    }

    private var effectiveIsPro: Bool {
        subscriptionRuntime.isProActive || isPro
    }

    private var recordsCountText: String {
        if effectiveFilter.isActive {
            return AppL10n.format("history.count.filtered", displayedRecords.count, allRecords.count)
        }
        return AppL10n.format("history.count.total", displayedRecords.count)
    }

    private var filterSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(effectiveFilter.summaryTokens, id: \.self) { token in
                        Text(token)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(primary.opacity(0.12), in: Capsule())
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Edit Filters") {
                    showFilterSheet = true
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(primary)

                Button("Clear") {
                    historyFilter = HistoryAdvancedFilter()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.gray)
            }
        }
    }

    private var defaultAddEndAt: Date {
        Date()
    }

    private var defaultAddStartAt: Date {
        Date().addingTimeInterval(TimeInterval(-viewModel.targetDurationSec))
    }

    private var ongoingRecord: FastingRecord? {
        allRecords.first { FastingRecordStatus.isOngoing($0.status) }
    }

    private var dayMetrics: [Date: FastingDayMetrics] {
        FastingAnalytics.dayMetricsByDate(records: allRecords)
    }

    private var hasOngoingSession: Bool {
        ongoingRecord != nil
    }

    private var todayCompletedRecord: FastingRecord? {
        allRecords
            .filter {
                FastingRecordStatus.isCompleted($0.status) &&
                ($0.endAt.map { Calendar.current.isDateInToday($0) } ?? false)
            }
            .max { ($0.endAt ?? .distantPast) < ($1.endAt ?? .distantPast) }
    }

    private var todayAbortedRecord: FastingRecord? {
        allRecords
            .filter {
                FastingRecordStatus.isNotCompleted($0.status) &&
                ($0.endAt.map { Calendar.current.isDateInToday($0) } ?? false)
            }
            .max { ($0.endAt ?? .distantPast) < ($1.endAt ?? .distantPast) }
    }

    private var todayPlanName: String {
        let planType = ongoingRecord?.planType
            ?? todayCompletedRecord?.planType
            ?? todayAbortedRecord?.planType
            ?? viewModel.targetPlanType
        let duration = ongoingRecord?.targetDurationSec
            ?? todayCompletedRecord?.targetDurationSec
            ?? todayAbortedRecord?.targetDurationSec
            ?? viewModel.targetDurationSec
        return AppL10n.format(
            "history.today.plan.format",
            PlanOption.displayName(forType: planType, durationSec: duration)
        )
    }

    private var todayBadgeText: String {
        if hasOngoingSession { return AppL10n.string("history.today.badge.in_progress") }
        if todayCompletedRecord != nil { return AppL10n.string("history.today.badge.completed") }
        if todayAbortedRecord != nil { return AppL10n.string("history.today.badge.not_completed") }
        return AppL10n.string("history.today.badge.none")
    }

    private var todayBadgeColor: Color {
        if hasOngoingSession { return primary }
        if todayCompletedRecord != nil { return .green }
        if todayAbortedRecord != nil { return .red }
        return .gray
    }

    private var todayStatusDescription: String {
        if todayCompletedRecord != nil {
            return AppL10n.string("history.today.status.completed")
        }
        if todayAbortedRecord != nil {
            return AppL10n.string("history.today.status.not_completed")
        }
        return AppL10n.string("history.today.status.none")
    }

    private var formattedElapsedForHistory: String {
        viewModel.elapsedText
    }

    private var formattedRemainingForHistory: String {
        viewModel.remainingText.replacingOccurrences(of: AppL10n.string("timer.remaining.suffix"), with: "")
    }

    private enum DayState {
        case goalMet
        case notCompleted
        case empty
    }

    private func stateForDay(_ day: Date) -> DayState {
        let startOfDay = Calendar.current.startOfDay(for: day)
        if let metrics = dayMetrics[startOfDay] {
            if metrics.hasGoalMet { return .goalMet }
            if metrics.hasAbortedSession { return .notCompleted }
        }
        return .empty
    }

    private func fillColor(for state: DayState, isToday: Bool) -> Color {
        switch state {
        case .goalMet:
            return .green
        case .notCompleted:
            return .red
        case .empty:
            return isToday ? primary.opacity(0.12) : .clear
        }
    }

    private func borderColor(for state: DayState) -> Color {
        switch state {
        case .empty:
            return Color.white.opacity(0.2)
        default:
            return .clear
        }
    }

    private func numberColor(for state: DayState, isToday: Bool) -> Color {
        switch state {
        case .goalMet, .notCompleted:
            return .white
        case .empty:
            return isToday ? primary : .gray
        }
    }

    private func dayNumber(_ date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    private func weekdayShort(_ date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "EEEEE")
        return formatter.string(from: date)
    }

    private func dateText(_ date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "yyyy-MM-dd")
        return formatter.string(from: date)
    }

    private func timeText(_ date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "HH:mm")
        return formatter.string(from: date)
    }

    private func shortDateTimeText(_ date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "MM/dd HH:mm")
        return formatter.string(from: date)
    }

    private func sessionRangeText(for record: FastingRecord) -> String {
        let start = record.startAt
        let end = record.endAt ?? Date()
        let isOngoing = FastingRecordStatus.isOngoing(record.status) && record.id == ongoingRecord?.id

        if Calendar.current.isDate(start, inSameDayAs: end) {
            let endLabel = isOngoing ? AppL10n.string("Now") : timeText(end)
            return "\(dateText(start)) · \(timeText(start)) - \(endLabel)"
        }

        let endLabel = isOngoing ? AppL10n.string("Now") : shortDateTimeText(end)
        return "\(shortDateTimeText(start)) - \(endLabel)"
    }

    private func planName(for record: FastingRecord) -> String {
        PlanOption.displayName(forType: record.planType, durationSec: record.targetDurationSec)
    }

    private func durationText(for record: FastingRecord) -> String {
        let endDate: Date
        if let endAt = record.endAt {
            endDate = endAt
        } else if FastingRecordStatus.isOngoing(record.status), record.id == ongoingRecord?.id {
            return formattedElapsedForHistory
        } else {
            endDate = Date()
        }
        let sec = max(0, Int(endDate.timeIntervalSince(record.startAt)))
        let h = sec / 3600
        let m = (sec % 3600) / 60
        return AppL10n.format("history.duration.hours_minutes", h, m)
    }

    private func statusBadgeText(for record: FastingRecord) -> String {
        if FastingRecordStatus.isCompleted(record.status) {
            return AppL10n.string("Completed")
        }
        if FastingRecordStatus.isNotCompleted(record.status) {
            return AppL10n.string("Not Completed")
        }
        if FastingRecordStatus.isOngoing(record.status) {
            return AppL10n.string("Ongoing")
        }
        return AppL10n.string("Ongoing")
    }

    private func statusBadgeColor(for record: FastingRecord) -> Color {
        if FastingRecordStatus.isCompleted(record.status) {
            return .green
        }
        if FastingRecordStatus.isNotCompleted(record.status) {
            return .red
        }
        if FastingRecordStatus.isOngoing(record.status) {
            return primary
        }
        return primary
    }

    private func isEditable(_ record: FastingRecord) -> Bool {
        !FastingRecordStatus.isOngoing(record.status)
    }

    private func applyEdit(_ draft: FastingRecordDraft, to record: FastingRecord) {
        record.planType = draft.planType
        record.targetDurationSec = draft.targetDurationSec
        record.startAt = draft.startAt
        record.endAt = draft.endAt
        record.status = draft.status
        record.isGoalMet = draft.isGoalMet
        record.abortReason = draft.abortReason
        try? modelContext.save()
    }

    private func deleteRecord(_ record: FastingRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    private func insertRecord(_ draft: FastingRecordDraft) {
        let record = FastingRecord(
            planType: draft.planType,
            targetDurationSec: draft.targetDurationSec,
            startAt: draft.startAt,
            endAt: draft.endAt,
            status: draft.status,
            isGoalMet: draft.isGoalMet,
            abortReason: draft.abortReason
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}

#Preview {
    HistoryView()
        .environmentObject(FastFlowTimerViewModel())
        .modelContainer(for: [FastingRecord.self, DailySummary.self], inMemory: true)
        .preferredColorScheme(.dark)
}
