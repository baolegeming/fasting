import SwiftUI

struct GiveUpReasonSheetView: View {
    let onSelectReason: (AbortReason) -> Void
    let onCancel: () -> Void

    private let primary = Color(hex: "ec5b13")
    private let cardDark = Color(hex: "1C1C1E")
    private let backgroundDark = Color(hex: "0F0F0F")

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 48, height: 6)
                .padding(.top, 10)
                .padding(.bottom, 20)

            Text("要放弃这次断食吗？")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 18)

            VStack(spacing: 10) {
                ForEach(AbortReason.allCases) { reason in
                    Button {
                        onSelectReason(reason)
                    } label: {
                        HStack(spacing: 12) {
                            Text(reason.emoji)
                                .font(.system(size: 22))
                            Text(reason.title)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.bottom, 18)

            Button {
                onCancel()
            } label: {
                Text("继续坚持")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .frame(height: 430)
        .background(backgroundDark)
    }
}

#Preview {
    GiveUpReasonSheetView(onSelectReason: { _ in }, onCancel: {})
        .preferredColorScheme(.dark)
}
