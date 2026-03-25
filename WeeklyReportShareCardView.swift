import SwiftUI

struct WeeklyReportShareCardView: View {
    let report: FastingWeeklyReport

    private let primary = Color(hex: "ec5b13")
    private let deepOrange = Color(hex: "a53a0e")
    private let background = Color(hex: "120f0d")
    private let cardBackground = Color.white.opacity(0.08)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [background, Color(hex: "24160f"), Color(hex: "130f0d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 18) {
                header
                hero
                metricsRow
                highlightsCard
                footer
            }
            .padding(24)
        }
        .frame(width: 360)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("FASTFLOW")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(primary)
                    .tracking(1.2)
                Text("Weekly Report")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                Text(reportRangeText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(primary)
                    .frame(width: 52, height: 52)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(report.headline)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(report.summary)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [primary, primary.opacity(0.88), deepOrange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private var metricsRow: some View {
        HStack(spacing: 10) {
            metricCard(title: AppL10n.string("Goal Days"), value: "\(report.completedGoalDays)/7")
            metricCard(title: AppL10n.string("Total Hours"), value: totalHoursText)
            metricCard(title: AppL10n.string("Rhythm"), value: report.startConsistency.rhythmLabel)
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppL10n.string("This Week"))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(primary)
                .textCase(.uppercase)
                .tracking(0.8)
            ForEach(displayHighlights, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(primary)
                        .padding(.top, 3)
                    Text(item)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var footer: some View {
        HStack {
            Text(AppL10n.string("Built for rhythm, not extremes."))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
            Spacer()
            Text(AppL10n.string("fast with FastFlow"))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(primary)
        }
    }

    private var displayHighlights: [String] {
        Array(report.highlights.prefix(3))
    }

    private var totalHoursText: String {
        AppL10n.format("weekly.share.hours", String(format: "%.1f", Double(report.totalFastingSeconds) / 3600.0))
    }

    private var reportRangeText: String {
        let formatter = AppL10n.formatter(dateFormat: "MMM d")
        let start = formatter.string(from: report.interval.start)
        let end = formatter.string(from: report.interval.end.addingTimeInterval(-1))
        return "\(start) - \(end)"
    }
}

#Preview {
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
            highlights: [
                "本周累计空腹 40.0 小时，活跃断食 5 天。",
                "本周有 4 天完成目标，完成类统计按断食结束日期归因。",
                "你的常见开始时间在 8:00 PM 左右，平均波动约 ±34 分钟。"
            ],
            focus: .keepRhythm
        )
    )
    .preferredColorScheme(.dark)
}
