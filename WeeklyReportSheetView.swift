import SwiftUI
import UIKit

struct WeeklyReportSheetView: View {
    let report: FastingWeeklyReport

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: FastFlowTimerViewModel
    @State private var showActionAlert = false
    @State private var actionAlertMessage = ""
    @State private var sharePreviewPayload: SharePreviewPayload?

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "121212")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    overviewCard
                    highlightsCard
                    focusCard
                    actionCard
                    scienceCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(backgroundDark.ignoresSafeArea())
            .navigationTitle(AppL10n.string("weekly.report.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        prepareShareCard()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.string("Done")) {
                        dismiss()
                    }
                    .foregroundStyle(primary)
                }
            }
            .alert(AppL10n.string("已更新"), isPresented: $showActionAlert) {
                Button(AppL10n.string("确定"), role: .cancel) {}
            } message: {
                Text(actionAlertMessage)
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $sharePreviewPayload) { payload in
                ShareImagePreviewSheetView(
                    image: payload.image,
                    activityItems: payload.activityItems,
                    onClose: {
                        sharePreviewPayload = nil
                    }
                )
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppL10n.string("Last 7 Days"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
            Text(reportRangeText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
            Text(report.headline)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
            Text(report.summary)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.82))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [primary, primary.opacity(0.86), Color(hex: "b63d0c")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle(AppL10n.string("weekly.card.overview"))
            HStack(spacing: 10) {
                metricTile(title: AppL10n.string("Total Hours"), value: totalHoursText)
                metricTile(title: AppL10n.string("Goal Days"), value: "\(report.completedGoalDays)/7")
            }
            HStack(spacing: 10) {
                metricTile(title: AppL10n.string("Active Days"), value: "\(report.activeDays)/7")
                metricTile(title: AppL10n.string("Rhythm"), value: report.startConsistency.rhythmLabel)
            }
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(AppL10n.string("weekly.card.highlights"))
            ForEach(report.highlights, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(primary)
                        .padding(.top, 3)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(AppL10n.string("weekly.card.focus"))
            Text(focusTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text(focusBody)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .lineSpacing(3)
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(AppL10n.string("weekly.card.try_next"))
            Text(actionHeadline)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            ForEach(actionSteps, id: \.self) { step in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(primary)
                        .padding(.top, 2)
                    Text(step)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !actionButtons.isEmpty {
                VStack(spacing: 8) {
                    ForEach(actionButtons) { action in
                        Button {
                            viewModel.applyCoachAction(action, removeFromCurrentNote: false) { message in
                                actionAlertMessage = message
                                showActionAlert = true
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(action.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(action.detail)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.72))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(primary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(primary.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var scienceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(AppL10n.string("weekly.card.science"))
            Text(scienceTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Text(scienceBody)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .lineSpacing(3)
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.gray)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func cardTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(primary)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private var totalHoursText: String {
        AppL10n.format(
            "weekly.share.hours",
            String(format: "%.1f", Double(report.totalFastingSeconds) / 3600.0)
        )
    }

    private var reportRangeText: String {
        let formatter = AppL10n.formatter(dateFormat: AppL10n.string("weekly.range.date_format"))
        let start = formatter.string(from: report.interval.start)
        let end = formatter.string(from: report.interval.end.addingTimeInterval(-1))
        return AppL10n.format("weekly.range.format", start, end)
    }

    private var focusTitle: String {
        switch report.focus {
        case .keepRhythm:
            return AppL10n.string("weekly.focus.keep.title")
        case .stabilizeStartTime:
            return AppL10n.string("weekly.focus.stabilize.title")
        case .improveCompletion:
            return AppL10n.string("weekly.focus.improve.title")
        case .gentlerPlan:
            return AppL10n.string("weekly.focus.gentler.title")
        case .buildHabit:
            return AppL10n.string("weekly.focus.build.title")
        }
    }

    private var focusBody: String {
        switch report.focus {
        case .keepRhythm:
            return AppL10n.string("weekly.focus.keep.body")
        case .stabilizeStartTime:
            return AppL10n.string("weekly.focus.stabilize.body")
        case .improveCompletion:
            return AppL10n.string("weekly.focus.improve.body")
        case .gentlerPlan:
            return AppL10n.string("weekly.focus.gentler.body")
        case .buildHabit:
            return AppL10n.string("weekly.focus.build.body")
        }
    }

    private var scienceTitle: String {
        scienceEntry.title
    }

    private var scienceBody: String {
        scienceEntry.userFacingBody
    }

    private var scienceEntry: FastingEducationEntry {
        switch report.focus {
        case .keepRhythm, .stabilizeStartTime, .buildHabit:
            return FastingEducationLibrary.consistencyMatters
        case .improveCompletion:
            return FastingEducationLibrary.durationFirst
        case .gentlerPlan:
            return FastingEducationLibrary.sessionBeforeCalendar
        }
    }

    private var actionHeadline: String {
        FastingCoachingGuidance.weeklyActionHeadline(for: report)
    }

    private var actionSteps: [String] {
        FastingCoachingGuidance.weeklyActionSteps(for: report)
    }

    private var actionButtons: [FastingCoachAction] {
        FastingCoachingGuidance.weeklyActionButtons(
            for: report,
            currentPlanType: viewModel.targetPlanType,
            currentDurationSec: viewModel.targetDurationSec
        )
    }

    private func prepareShareCard() {
        let shareContent = WeeklyShareCardContent.make(report: report)
        if let image = renderShareImage(content: {
            WeeklyReportShareCardView(content: shareContent)
        }) {
            sharePreviewPayload = SharePreviewPayload(
                image: image,
                activityItems: [image, shareContent.shareCaption]
            )
        } else {
            actionAlertMessage = AppL10n.string("weekly.share.failed")
            showActionAlert = true
        }
    }
}

#Preview {
    WeeklyReportSheetView(
        report: FastingWeeklyReport(
            interval: DateInterval(start: .now.addingTimeInterval(-6 * 86400), end: .now),
            totalFastingSeconds: 40 * 3600,
            activeDays: 5,
            completedGoalDays: 4,
            completedSessions: 4,
            abortedSessions: 1,
            averageDailyHours: 5.7,
            bestDay: .now,
            bestDayHours: 12.0,
            startConsistency: FastingStartConsistency(
                samples: [],
                typicalStartMinute: 20 * 60,
                averageDriftMinutes: 34
            ),
            headline: "你的断食节奏正在稳定下来",
            summary: "最近 7 天你有 5 天进入断食、4 天完成目标，平均每天约 5.7 小时空腹。",
            highlights: [
                "本周累计空腹 40.0 小时，活跃断食 5 天。",
                "本周有 4 天完成目标，完成类统计按断食结束日期归因。"
            ],
            focus: .keepRhythm
        )
    )
    .environmentObject(FastFlowTimerViewModel())
    .preferredColorScheme(.dark)
}
