import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct DailyCompletionShareCardContent: Identifiable {
    let id = UUID()
    let durationText: String
    let resultLine: String
    let timeRangeLine: String
    let chips: [String]
    let emotionalLine: String
    let shareCaption: String

    static func make(
        startAt: Date,
        endAt: Date,
        planType: String,
        targetDurationSec: Int,
        weeklyCompletedCount: Int
    ) -> DailyCompletionShareCardContent {
        let planName = PlanOption.displayName(forType: planType, durationSec: targetDurationSec)
        let resultLine = ShareCardCopy.dailyResultLine(planName: planName)
        let emotionalLine = ShareCardCopy.dailyEmotionalLine()
        let chips = [
            ShareCardCopy.planChip(planName: planName),
            ShareCardCopy.completedChip,
            ShareCardCopy.weeklyCompletedChip(count: max(weeklyCompletedCount, 1))
        ]

        return DailyCompletionShareCardContent(
            durationText: ShareCardFormatter.durationText(from: startAt, to: endAt),
            resultLine: resultLine,
            timeRangeLine: ShareCardFormatter.timeRangeLine(startAt: startAt, endAt: endAt),
            chips: chips,
            emotionalLine: emotionalLine,
            shareCaption: ShareCardCopy.dailyShareCaption(resultLine: resultLine, emotionalLine: emotionalLine)
        )
    }
}

struct WeeklyShareCardContent {
    let rangeText: String
    let headline: String
    let supportingLine: String
    let chips: [String]
    let emotionalLine: String
    let shareCaption: String

    static func make(report: FastingWeeklyReport) -> WeeklyShareCardContent {
        let headline = ShareCardCopy.weeklyHeadline(completedDays: report.completedGoalDays)
        let emotionalLine = ShareCardCopy.weeklyEmotionalLine()
        let supportingLine = ShareCardCopy.weeklySupportingLine(report: report)
        let chips = [
            ShareCardCopy.weeklyCompletedDaysChip(count: report.completedGoalDays),
            ShareCardCopy.weeklyActiveDaysChip(count: report.activeDays),
            ShareCardCopy.weeklyHoursChip(totalSeconds: report.totalFastingSeconds)
        ]

        return WeeklyShareCardContent(
            rangeText: ShareCardFormatter.weeklyRangeText(interval: report.interval),
            headline: headline,
            supportingLine: supportingLine,
            chips: chips,
            emotionalLine: emotionalLine,
            shareCaption: ShareCardCopy.weeklyShareCaption(headline: headline, emotionalLine: emotionalLine)
        )
    }
}

struct SharePreviewPayload: Identifiable {
    let id = UUID()
    let image: UIImage
    let activityItems: [Any]
}

struct DailyCompletionShareCardView: View {
    let content: DailyCompletionShareCardContent

    var body: some View {
        ShareCardCanvas {
            VStack(alignment: .leading, spacing: 18) {
                ShareCardTopBar(
                    eyebrow: "THIS FAST",
                    rangeText: nil
                )

                Spacer(minLength: 8)

                Text(ShareCardCopy.dailyDurationEyebrow)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .tracking(0.6)

                Text(content.durationText)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(-1.8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(content.resultLine)
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(content.timeRangeLine)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }

                ShareCardChipFlow(chips: content.chips, layout: .singleRow)

                Spacer()

                Text(content.emotionalLine)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ShareCardStyle.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 34)
            }
        }
    }
}

struct WeeklyReportShareCardView: View {
    let content: WeeklyShareCardContent

    init(report: FastingWeeklyReport) {
        self.content = WeeklyShareCardContent.make(report: report)
    }

    init(content: WeeklyShareCardContent) {
        self.content = content
    }

    var body: some View {
        ShareCardCanvas {
            VStack(alignment: .leading, spacing: 18) {
                ShareCardTopBar(
                    eyebrow: "WEEKLY RHYTHM",
                    rangeText: content.rangeText
                )

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 10) {
                    Text(content.headline)
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(content.supportingLine)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                ShareCardChipFlow(chips: content.chips, layout: .singleRow)

                Spacer()

                Text(content.emotionalLine)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ShareCardStyle.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 42)
            }
        }
    }
}

struct DailyCompletionShareSheetView: View {
    let content: DailyCompletionShareCardContent
    let onClose: () -> Void

    @State private var previewImage: UIImage?

    var body: some View {
        Group {
            if let previewImage {
                ShareImagePreviewSheetView(
                    image: previewImage,
                    activityItems: [previewImage, content.shareCaption],
                    onClose: onClose
                )
            } else {
                ZStack {
                    ShareCardStyle.sheetBackground
                        .ignoresSafeArea()

                    ProgressView()
                        .tint(.white)
                }
                .task {
                    renderPreviewIfNeeded()
                }
            }
        }
    }

    private func renderPreviewIfNeeded() {
        guard previewImage == nil else { return }
        previewImage = renderShareImage {
            DailyCompletionShareCardView(content: content)
        }
    }
}

struct ShareImagePreviewSheetView: View {
    let image: UIImage
    let activityItems: [Any]
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                ShareCardStyle.sheetBackground
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer(minLength: 8)

                    GeometryReader { geometry in
                        VStack {
                            Spacer(minLength: 0)
                            Image(uiImage: image)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(
                                    maxWidth: min(geometry.size.width * 0.84, 340),
                                    maxHeight: geometry.size.height * 0.76
                                )
                                .shadow(color: .black.opacity(0.28), radius: 28, y: 18)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    VStack(spacing: 12) {
                        Button {
                            showShareSheet = true
                        } label: {
                            Text(AppL10n.string("share.card.cta"))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(ShareCardStyle.primary)
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            close()
                        } label: {
                            Text(AppL10n.string("share.card.later"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.82))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle(AppL10n.string("share.card.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.string("Done")) {
                        close()
                    }
                    .foregroundStyle(ShareCardStyle.primary)
                }
            }
            .toolbarBackground(ShareCardStyle.sheetBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                ActivityShareSheetView(activityItems: activityItems)
            }
        }
    }

    private func close() {
        onClose()
        dismiss()
    }
}

private enum ShareCardStyle {
    static let primary = Color(hex: "ec8b2d")
    static let primaryDeep = Color(hex: "a55718")
    static let background = Color(hex: "0f1713")
    static let backgroundMid = Color(hex: "16231d")
    static let backgroundLight = Color(hex: "21342b")
    static let cardBackground = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.07)
    static let sheetBackground = Color(hex: "0b0f0d")
}

private struct ShareCardCanvas<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    ShareCardStyle.background,
                    ShareCardStyle.backgroundMid,
                    ShareCardStyle.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            ShareCardStyle.primary.opacity(0.30),
                            ShareCardStyle.primaryDeep.opacity(0.08),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 220, height: 220)
                .blur(radius: 18)
                .offset(x: 170, y: -40)

            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.03))
                .frame(width: 140, height: 140)
                .blur(radius: 24)
                .offset(x: 210, y: 110)

            content
                .padding(24)
        }
        .frame(width: 360, height: 780)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(ShareCardStyle.cardStroke, lineWidth: 1)
        )
    }
}

private struct ShareCardHeader: View {
    let eyebrow: String
    let rangeText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FASTFLOW")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(ShareCardStyle.primary)
                .tracking(1.2)

            Text(eyebrow)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.65))
                .tracking(1.0)

            if let rangeText {
                Text(rangeText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }
}

private struct ShareCardTopBar: View {
    let eyebrow: String
    let rangeText: String?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ShareCardHeader(
                eyebrow: eyebrow,
                rangeText: rangeText
            )

            Spacer(minLength: 0)

            ShareCardQRCodeBadge()
        }
    }
}

private struct ShareCardQRCodeBadge: View {
    private let qrCodeImage = ShareCardQRCodeRenderer.image(for: ShareCardCopy.downloadURL)

    var body: some View {
        VStack(spacing: 6) {
            if let qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white)
                    )
            }

            Text(ShareCardCopy.downloadHint)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .tracking(0.3)
        }
    }
}

private struct ShareCardChipFlow: View {
    enum Layout {
        case wrapped
        case singleRow
    }

    let chips: [String]
    var layout: Layout = .wrapped

    var body: some View {
        Group {
            switch layout {
            case .wrapped:
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(chunkedChips, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { chip in
                                chipView(chip, compact: false)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            case .singleRow:
                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        chipView(chip, compact: true)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func chipView(_ chip: String, compact: Bool) -> some View {
        Text(chip)
            .font(.system(size: compact ? 12 : 13, weight: .bold))
            .foregroundStyle(.white.opacity(0.88))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, compact ? 10 : 12)
            .padding(.vertical, compact ? 9 : 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(ShareCardStyle.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ShareCardStyle.cardStroke, lineWidth: 1)
            )
    }

    private var chunkedChips: [[String]] {
        stride(from: 0, to: chips.count, by: 2).map { start in
            Array(chips[start..<min(start + 2, chips.count)])
        }
    }
}

private enum ShareCardCopy {
    static let downloadURL = URL(string: "https://fasting-nu.vercel.app/download")!

    private static var language: AppLanguage {
        AppLanguage.resolved()
    }

    static func dailyResultLine(planName: String) -> String {
        switch language {
        case .zh:
            let templates = [
                "这次按计划完成了 %@ 断食",
                "这次顺利完成了 %@ 断食",
                "又一次按计划完成 %@，今天也不错"
            ]
            return String(format: templates.randomElement() ?? templates[0], planName)
        case .en:
            let templates = [
                "This %@ fast went exactly to plan",
                "Completed my %@ fast right on target",
                "Another %@ fast done and dusted"
            ]
            return String(format: templates.randomElement() ?? templates[0], planName)
        }
    }

    static var dailyDurationEyebrow: String {
        switch language {
        case .zh:
            return "已坚持"
        case .en:
            return "STAYED WITH IT"
        }
    }

    static func dailyEmotionalLine() -> String {
        switch language {
        case .zh:
            let options = [
                "又坚持一天，我先得意一下",
                "今天也稳稳拿下，先夸自己一句",
                "又完成一次，我先偷偷开心一下"
            ]
            return options.randomElement() ?? options[0]
        case .en:
            let options = [
                "One more solid day. Let me enjoy this a second.",
                "That one felt good. I'll take the win.",
                "Another one done. Quietly proud of this."
            ]
            return options.randomElement() ?? options[0]
        }
    }

    static func weeklyHeadline(completedDays: Int) -> String {
        switch language {
        case .zh:
            let templates = [
                "这周完成了 %d 天，状态比上周更稳了",
                "这周完成了 %d 天，已经很不错了",
                "这周认真坚持了 %d 天，给自己点个赞"
            ]
            return String(format: templates.randomElement() ?? templates[0], completedDays)
        case .en:
            let templates = [
                "Completed %d days this week, and it felt steadier too",
                "%d solid fasting days this week. I'll take that",
                "Held it together for %d days this week. Not bad at all"
            ]
            return String(format: templates.randomElement() ?? templates[0], completedDays)
        }
    }

    static func weeklySupportingLine(report: FastingWeeklyReport) -> String {
        switch language {
        case .zh:
            let hours = String(format: "%.1f", Double(report.totalFastingSeconds) / 3600.0)
            return "7 天里有 \(report.activeDays) 天进入断食，累计空腹 \(hours) 小时"
        case .en:
            let hours = String(format: "%.1f", Double(report.totalFastingSeconds) / 3600.0)
            return "\(report.activeDays) active fasting days this week, \(hours) hours total"
        }
    }

    static func weeklyEmotionalLine() -> String {
        switch language {
        case .zh:
            let options = [
                "这周也稳住了，我先夸自己一句",
                "这周没掉链子，我先给自己加个鸡腿",
                "这周保持得不错，先悄悄得意一下"
            ]
            return options.randomElement() ?? options[0]
        case .en:
            let options = [
                "Stayed on track this week. I'll give myself that.",
                "No dropped balls this week. I'll count that as a win.",
                "This week held together nicely. Feeling good about it."
            ]
            return options.randomElement() ?? options[0]
        }
    }

    static func planChip(planName: String) -> String {
        switch language {
        case .zh:
            return "计划 \(planName)"
        case .en:
            return "Plan \(planName)"
        }
    }

    static var completedChip: String {
        switch language {
        case .zh: return "已达标"
        case .en: return "Goal hit"
        }
    }

    static func weeklyCompletedChip(count: Int) -> String {
        switch language {
        case .zh:
            return "本周第 \(count) 次完成"
        case .en:
            return "Week win \(count)"
        }
    }

    static func weeklyCompletedDaysChip(count: Int) -> String {
        switch language {
        case .zh:
            return "完成 \(count)/7"
        case .en:
            return "Done \(count)/7"
        }
    }

    static func weeklyActiveDaysChip(count: Int) -> String {
        switch language {
        case .zh:
            return "活跃 \(count)/7"
        case .en:
            return "Active \(count)/7"
        }
    }

    static func weeklyHoursChip(totalSeconds: Int) -> String {
        let hours = String(format: "%.1f", Double(totalSeconds) / 3600.0)
        switch language {
        case .zh:
            return "累计 \(hours)h"
        case .en:
            return "Total \(hours)h"
        }
    }

    static func dailyShareCaption(resultLine: String, emotionalLine: String) -> String {
        switch language {
        case .zh:
            return "\(resultLine)，\(emotionalLine)"
        case .en:
            return "\(resultLine). \(emotionalLine)"
        }
    }

    static func weeklyShareCaption(headline: String, emotionalLine: String) -> String {
        switch language {
        case .zh:
            return "\(headline)，\(emotionalLine)"
        case .en:
            return "\(headline). \(emotionalLine)"
        }
    }

    static var downloadHint: String {
        switch language {
        case .zh:
            return "扫码下载"
        case .en:
            return "SCAN TO GET"
        }
    }
}

private enum ShareCardFormatter {
    static func durationText(from startAt: Date, to endAt: Date) -> String {
        let totalMinutes = max(Int(endAt.timeIntervalSince(startAt)) / 60, 0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(String(format: "%02d", minutes))m"
    }

    static func timeRangeLine(startAt: Date, endAt: Date) -> String {
        let timeFormatter = AppL10n.formatter(dateFormat: "HH:mm")
        let startLabel = relativeDayLabel(for: startAt, relativeTo: endAt)
        let endLabel = relativeDayLabel(for: endAt, relativeTo: endAt)

        switch AppLanguage.resolved() {
        case .zh:
            return "从\(startLabel) \(timeFormatter.string(from: startAt)) 到\(endLabel) \(timeFormatter.string(from: endAt))"
        case .en:
            return "\(startLabel) \(timeFormatter.string(from: startAt)) - \(endLabel) \(timeFormatter.string(from: endAt))"
        }
    }

    static func weeklyRangeText(interval: DateInterval) -> String {
        let formatter = AppL10n.formatter(dateFormat: "MM.dd")
        let endDate = interval.end.addingTimeInterval(-1)
        return "\(formatter.string(from: interval.start)) - \(formatter.string(from: endDate))"
    }

    private static func relativeDayLabel(for date: Date, relativeTo anchor: Date) -> String {
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        let startOfAnchor = calendar.startOfDay(for: anchor)
        let dayOffset = calendar.dateComponents([.day], from: startOfDate, to: startOfAnchor).day ?? 0

        switch AppLanguage.resolved() {
        case .zh:
            if dayOffset == 0 {
                return "今天"
            }
            if dayOffset == 1 {
                let hour = calendar.component(.hour, from: date)
                return hour >= 18 ? "昨晚" : "昨天"
            }
            return AppL10n.formatter(dateFormat: "MM.dd").string(from: date)
        case .en:
            if dayOffset == 0 {
                return "Today"
            }
            if dayOffset == 1 {
                return "Yesterday"
            }
            return AppL10n.formatter(dateFormat: "MM.dd").string(from: date)
        }
    }
}

@MainActor
func renderShareImage<Content: View>(
    @ViewBuilder content: () -> Content
) -> UIImage? {
    let renderer = ImageRenderer(
        content: content()
            .preferredColorScheme(.dark)
    )
    renderer.scale = 3
    return renderer.uiImage
}

private enum ShareCardQRCodeRenderer {
    private static let context = CIContext()

    static func image(for url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(url.absoluteString.utf8), forKey: "inputMessage")
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

#Preview("Weekly Share Card") {
    WeeklyReportShareCardView(
        report: FastingWeeklyReport(
            interval: DateInterval(start: .now.addingTimeInterval(-6 * 86400), end: .now),
            totalFastingSeconds: 40 * 3600,
            activeDays: 5,
            completedGoalDays: 4,
            completedSessions: 4,
            abortedSessions: 1,
            averageDailyHours: 5.7,
            bestDay: .now,
            bestDayHours: 12,
            startConsistency: FastingStartConsistency(
                samples: [],
                typicalStartMinute: 20 * 60,
                averageDriftMinutes: 34
            ),
            headline: "你的断食节奏正在稳定下来",
            summary: "最近 7 天你有 5 天进入断食、4 天完成目标，平均每天约 5.7 小时空腹。",
            highlights: [],
            focus: .keepRhythm
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Daily Share Card") {
    DailyCompletionShareCardView(
        content: .make(
            startAt: .now.addingTimeInterval(-16 * 3600 - 3 * 60),
            endAt: .now,
            planType: PlanOption.plan16_8.type,
            targetDurationSec: PlanOption.plan16_8.durationSec,
            weeklyCompletedCount: 4
        )
    )
    .preferredColorScheme(.dark)
}
