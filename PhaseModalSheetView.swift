import SwiftUI

struct PhaseModalSheetView: View {
    let phase: PhaseInfo
    let onClose: () -> Void

    private let primary = Color(hex: "ec5b13")
    private let cardDark = Color(hex: "1C1C1E")
    private let guidanceBackground = Color.white.opacity(0.03)

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 48, height: 6)
                .padding(.top, 10)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 14) {
                    Text(phase.icon)
                        .font(.system(size: 48))

                    VStack(spacing: 4) {
                        Text(phase.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text(phase.timeRange)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(primary)
                    }

                    Text(phase.description)
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)

                    educationalGuardrailCard
                    guidanceCard
                    phaseOverview

                    Button {
                        onClose()
                    } label: {
                        Text(AppL10n.string("Keep Going!"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(primary, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .background(cardDark)
    }

    private var phaseOverview: some View {
        HStack(spacing: 8) {
            ForEach(PhaseInfo.all) { item in
                VStack(spacing: 6) {
                    Text(item.icon)
                        .font(.system(size: 18))
                    Text(item.shortLabel)
                        .font(.system(size: 10, weight: item.id == phase.id ? .bold : .medium))
                        .foregroundStyle(item.id == phase.id ? primary : .gray)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(guidanceBackground, in: RoundedRectangle(cornerRadius: 16))
    }

    private var educationalGuardrailCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppL10n.string("How to Read This Phase"))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(primary)
                .textCase(.uppercase)
                .tracking(0.8)
            Text(AppL10n.string("These phase cues are based on fasting duration. They help explain progress and rhythm, but they are not a medical diagnosis."))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineSpacing(3)
            Text(FastingProductGuardrail.phasesAreEducational.guidance)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(guidanceBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var guidanceCard: some View {
        let guidance = FastingCoachingGuidance.phaseGuidance(for: phase)

        return VStack(alignment: .leading, spacing: 10) {
            Text(guidance.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(guidance.body)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .lineSpacing(3)

            VStack(alignment: .leading, spacing: 4) {
                Text(guidance.tipTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(primary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(guidance.tipBody)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineSpacing(3)
            }

            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(primary)
                Text(guidance.educationEntry.title)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(guidanceBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.7).ignoresSafeArea()
        VStack {
            Spacer()
            PhaseModalSheetView(phase: PhaseInfo.all[3], onClose: {})
        }
    }
    .preferredColorScheme(.dark)
}
