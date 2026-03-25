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
                Text("Fast Phases")
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
                ForEach(0..<6, id: \.self) { index in
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

#Preview {
    ZStack {
        Color(hex: "0F0F0F").ignoresSafeArea()
        PhaseCardView(
            phaseBadgeText: "Stage 3 of 6",
            activeStageCount: 3,
            phaseItems: PhaseInfo.all.map {
                FastFlowPhaseItem(id: $0.id, title: $0.shortLabel, symbol: $0.cardSymbol)
            }
        )
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}
