import SwiftUI

struct ActionButtonsView: View {
    let status: FastFlowTimerStatus
    let hasReachedGoal: Bool
    let onPrimaryAction: () -> Void

    private let primary = Color(hex: "ec5b13")

    private var primaryActionTitle: String {
        switch status {
        case .notStarted:
            return AppL10n.string("Start Fast")
        case .fasting:
            return hasReachedGoal
                ? AppL10n.string("session.action.complete")
                : AppL10n.string("session.action.end_early")
        }
    }

    var body: some View {
        Button {
            onPrimaryAction()
        } label: {
            Text(primaryActionTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(primary)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color(hex: "0F0F0F").ignoresSafeArea()
        ActionButtonsView(
            status: .fasting,
            hasReachedGoal: false,
            onPrimaryAction: {}
        )
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}
