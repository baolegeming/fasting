import SwiftUI

struct NativeAdSlotView: View {
    let presentation: NativeAdPresentation
    let onUpgrade: () -> Void

    private let primary = Color(hex: "ec5b13")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        #if canImport(GoogleMobileAds)
        AdMobNativeAdView(presentation: presentation, onUpgrade: onUpgrade)
        #else
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(presentation.mode.badgeText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(primary.opacity(0.14), in: Capsule())

                Spacer()

                Button(AppL10n.string("ads.go_ad_free")) {
                    onUpgrade()
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(presentation.headline)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text(presentation.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .frame(height: 88)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(primary)
                        Text(presentation.mode.runtimeNote)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                )

            Text(presentation.footer)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(presentation.mode.badgeText). \(presentation.headline). \(presentation.detail)")
        #endif
    }
}
