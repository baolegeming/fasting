import SwiftUI

enum HistoryRangeFilter: String, CaseIterable, Identifiable {
    case all
    case last7Days
    case last30Days
    case last90Days

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return AppL10n.string("history.filter.range.all")
        case .last7Days:
            return AppL10n.string("history.filter.range.last7")
        case .last30Days:
            return AppL10n.string("history.filter.range.last30")
        case .last90Days:
            return AppL10n.string("history.filter.range.last90")
        }
    }

    func lowerBound(now: Date = Date(), calendar: Calendar = .current) -> Date? {
        switch self {
        case .all:
            return nil
        case .last7Days:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
        case .last30Days:
            return calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now))
        case .last90Days:
            return calendar.date(byAdding: .day, value: -89, to: calendar.startOfDay(for: now))
        }
    }
}

enum HistoryStatusFilter: String, CaseIterable, Identifiable {
    case all
    case completed
    case notCompleted = "not_completed"
    case ongoing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return AppL10n.string("history.filter.status.all")
        case .completed:
            return AppL10n.string("history.filter.status.completed")
        case .notCompleted:
            return AppL10n.string("history.filter.status.not_completed")
        case .ongoing:
            return AppL10n.string("history.filter.status.ongoing")
        }
    }

    var statusValue: String? {
        switch self {
        case .all:
            return nil
        case .completed:
            return FastingRecordStatus.completed
        case .notCompleted:
            return FastingRecordStatus.notCompleted
        case .ongoing:
            return FastingRecordStatus.ongoing
        }
    }
}

enum HistoryPlanFilter: String, CaseIterable, Identifiable {
    case all
    case plan16_8
    case plan18_6
    case plan20_4
    case omad
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return AppL10n.string("history.filter.plan.all")
        case .plan16_8:
            return "16:8"
        case .plan18_6:
            return "18:6"
        case .plan20_4:
            return "20:4"
        case .omad:
            return "OMAD"
        case .custom:
            return AppL10n.string("history.filter.plan.custom")
        }
    }

    var planType: String? {
        switch self {
        case .all:
            return nil
        case .plan16_8:
            return PlanOption.plan16_8.type
        case .plan18_6:
            return PlanOption.plan18_6.type
        case .plan20_4:
            return PlanOption.plan20_4.type
        case .omad:
            return PlanOption.omad.type
        case .custom:
            return PlanOption.customType
        }
    }
}

enum HistoryAbortReasonFilter: String, CaseIterable, Identifiable {
    case all
    case hungry
    case social
    case unwell
    case planAdjustment
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return AppL10n.string("history.filter.reason.all")
        case .hungry:
            return AppL10n.string("abort.reason.hungry")
        case .social:
            return AppL10n.string("abort.reason.social")
        case .unwell:
            return AppL10n.string("abort.reason.unwell")
        case .planAdjustment:
            return AppL10n.string("abort.reason.plan_adjustment")
        case .other:
            return AppL10n.string("abort.reason.other")
        }
    }

    var abortReasonValue: String? {
        switch self {
        case .all:
            return nil
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

struct HistoryAdvancedFilter: Equatable {
    var range: HistoryRangeFilter = .all
    var status: HistoryStatusFilter = .all
    var plan: HistoryPlanFilter = .all
    var abortReason: HistoryAbortReasonFilter = .all

    var isActive: Bool {
        range != .all || status != .all || plan != .all || abortReason != .all
    }

    var summaryTokens: [String] {
        var tokens: [String] = []

        if range != .all {
            tokens.append(range.title)
        }
        if status != .all {
            tokens.append(status.title)
        }
        if plan != .all {
            tokens.append(plan.title)
        }
        if abortReason != .all {
            tokens.append(AppL10n.format("history.filter.reason.token", abortReason.title))
        }

        return tokens
    }

    func matches(_ record: FastingRecord, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        if let lowerBound = range.lowerBound(now: now, calendar: calendar) {
            let sessionEnd = FastingAnalytics.effectiveSessionEnd(for: record, now: now) ?? record.startAt
            guard sessionEnd >= lowerBound else { return false }
        }

        if let expectedStatus = status.statusValue {
            if expectedStatus == FastingRecordStatus.notCompleted {
                guard FastingRecordStatus.isNotCompleted(record.status) else { return false }
            } else if record.status != expectedStatus {
                return false
            }
        }

        if let expectedPlanType = plan.planType {
            if expectedPlanType == PlanOption.customType {
                guard PlanOption.isCustom(type: record.planType) else { return false }
            } else if record.planType != expectedPlanType {
                return false
            }
        }

        if let expectedAbortReason = abortReason.abortReasonValue {
            guard record.abortReason == expectedAbortReason else { return false }
        }

        return true
    }
}

struct HistoryFilterSheetView: View {
    @Binding var filter: HistoryAdvancedFilter

    @Environment(\.dismiss) private var dismiss

    @State private var draft: HistoryAdvancedFilter

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "0F0F0F")
    private let cardDark = Color(hex: "1C1C1E")

    init(filter: Binding<HistoryAdvancedFilter>) {
        _filter = filter
        _draft = State(initialValue: filter.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section(
                        title: "Time Range",
                        options: HistoryRangeFilter.allCases,
                        selection: $draft.range
                    )
                    section(
                        title: "Status",
                        options: HistoryStatusFilter.allCases,
                        selection: $draft.status
                    )
                    section(
                        title: "Plan",
                        options: HistoryPlanFilter.allCases,
                        selection: $draft.plan
                    )
                    section(
                        title: "End Reason",
                        options: HistoryAbortReasonFilter.allCases,
                        selection: $draft.abortReason
                    )
                }
                .padding(16)
            }
            .background(backgroundDark.ignoresSafeArea())
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.gray)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        filter = draft
                        dismiss()
                    }
                    .foregroundStyle(primary)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Clear All") {
                        draft = HistoryAdvancedFilter()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(primary)
                }
            }
        }
    }

    private func section<Option: CaseIterable & Identifiable & Hashable>(
        title: String,
        options: Option.AllCases,
        selection: Binding<Option>
    ) -> some View where Option.AllCases: RandomAccessCollection, Option: HistoryFilterOption {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(primary)
                .textCase(.uppercase)
                .tracking(0.8)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(Array(options), id: \.id) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(option.historyFilterTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(selection.wrappedValue == option ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selection.wrappedValue == option ? primary.opacity(0.18) : cardDark)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selection.wrappedValue == option ? primary : Color.white.opacity(0.06), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

protocol HistoryFilterOption {
    var historyFilterTitle: String { get }
}

extension HistoryRangeFilter: HistoryFilterOption {
    var historyFilterTitle: String { title }
}

extension HistoryStatusFilter: HistoryFilterOption {
    var historyFilterTitle: String { title }
}

extension HistoryPlanFilter: HistoryFilterOption {
    var historyFilterTitle: String { title }
}

extension HistoryAbortReasonFilter: HistoryFilterOption {
    var historyFilterTitle: String { title }
}

#Preview {
    HistoryFilterSheetView(filter: .constant(HistoryAdvancedFilter()))
        .preferredColorScheme(.dark)
}
