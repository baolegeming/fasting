import SwiftUI

struct PhaseCardView: View {
    let phaseBadgeText: String
    let activeStageCount: Int
    let phaseItems: [FastFlowPhaseItem]

    private let primary = Color(hex: "ec5b13")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(AppL10n.string("phase.card.title"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                Spacer()
                Text(phaseBadgeText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(primary.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 6) {
                ForEach(0..<phaseItems.count, id: \.self) { index in
                    Capsule()
                        .fill(index < activeStageCount ? primary : Color.gray.opacity(0.35))
                        .frame(height: 6)
                }
            }

            HStack(spacing: 6) {
                ForEach(Array(phaseItems.enumerated()), id: \.element.id) { idx, item in
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 12, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 10, weight: idx + 1 == activeStageCount ? .bold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(foregroundForPhase(index: idx))
                }
            }
        }
        .padding(20)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 18))
    }

    private func foregroundForPhase(index: Int) -> Color {
        let activeIndex = activeStageCount - 1
        if activeStageCount == 0 {
            return .gray.opacity(0.45)
        }
        if index == activeIndex {
            return primary
        }
        if index < activeStageCount {
            return .gray.opacity(0.55)
        }
        return .gray.opacity(0.45)
    }
}

struct CustomProgressCardView: View {
    let badgeText: String
    let planName: String
    let progress: Double
    let elapsedText: String
    let targetHours: Int

    private let primary = Color(hex: "ec5b13")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(AppL10n.string("phase.custom.title"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                Spacer()
                Text(badgeText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(primary.opacity(0.12), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(planName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(AppL10n.format("phase.custom.elapsed", elapsedText))
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
            }

            ProgressView(value: min(max(progress, 0), 1))
                .tint(primary)

            Text(AppL10n.format("phase.custom.target", targetHours))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray)
        }
        .padding(20)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    ZStack {
        Color(hex: "0F0F0F").ignoresSafeArea()
        PhaseCardView(
            phaseBadgeText: "开始燃脂",
            activeStageCount: 3,
            phaseItems: PhaseInfo.detailPhases(forPlanType: PlanOption.plan18_6.type, targetDurationSec: PlanOption.plan18_6.durationSec).map {
                FastFlowPhaseItem(id: $0.id, title: $0.shortLabel, symbol: $0.cardSymbol)
            }
        )
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}
