import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
import UIKit

enum NativeAdLoadState: Equatable {
    case idle
    case loading
    case loaded
    case unavailable(String)
}

@MainActor
final class NativeAdSlotLoader: NSObject, ObservableObject {
    @Published private(set) var nativeAd: NativeAd?
    @Published private(set) var loadState: NativeAdLoadState = .idle

    private let placement: AdPlacement
    private var adLoader: AdLoader?
    private var lastMode: AdInventoryMode?

    init(placement: AdPlacement) {
        self.placement = placement
    }

    func loadIfNeeded(mode: AdInventoryMode, canRequestAds: Bool) {
        guard canRequestAds else {
            loadState = .unavailable(AppL10n.string("ads.waiting_for_consent"))
            return
        }

        guard let adUnitID = MonetizationPolicy.nativeAdUnitID(for: placement, adMode: mode) else {
            loadState = .unavailable(AppL10n.string("ads.no_unit_configured"))
            return
        }

        if lastMode == mode, nativeAd != nil || loadState == .loading {
            return
        }

        lastMode = mode
        loadState = .loading

        let options = NativeAdMediaAdLoaderOptions()
        options.mediaAspectRatio = .landscape

        let adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: [options]
        )
        adLoader.delegate = self
        self.adLoader = adLoader
        adLoader.load(Request())
    }
}

@MainActor
extension NativeAdSlotLoader: @preconcurrency AdLoaderDelegate, @preconcurrency NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        loadState = .loaded
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        loadState = .unavailable(error.localizedDescription)
    }
}

private final class FastFlowNativeAdCardView: NativeAdView {
    let adBadgeLabel = UILabel()
    let sponsoredLabel = UILabel()
    let titleLabel = UILabel()
    let bodyLabel = UILabel()
    let advertiserLabel = UILabel()
    let iconImageView = UIImageView()
    let mediaDisplayView = MediaView()
    let callToActionButton = UIButton(type: .system)
    let infoStack = UIStackView()
    let topMetaStack = UIStackView()
    let cardInsetView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
    }

    private func configureUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        layer.cornerRadius = 18
        clipsToBounds = true

        cardInsetView.translatesAutoresizingMaskIntoConstraints = false
        cardInsetView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        cardInsetView.layer.cornerRadius = 18
        cardInsetView.layer.borderWidth = 1
        cardInsetView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        adBadgeLabel.text = AppL10n.string("ads.sponsored")
        adBadgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        adBadgeLabel.textColor = UIColor(red: 0.93, green: 0.36, blue: 0.07, alpha: 1.0)
        adBadgeLabel.backgroundColor = UIColor(red: 0.93, green: 0.36, blue: 0.07, alpha: 0.16)
        adBadgeLabel.layer.cornerRadius = 10
        adBadgeLabel.clipsToBounds = true
        adBadgeLabel.textAlignment = .center

        sponsoredLabel.translatesAutoresizingMaskIntoConstraints = false
        sponsoredLabel.text = AppL10n.string("ads.featured_partner")
        sponsoredLabel.font = .systemFont(ofSize: 12, weight: .medium)
        sponsoredLabel.textColor = UIColor.white.withAlphaComponent(0.55)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        bodyLabel.numberOfLines = 3

        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        advertiserLabel.font = .systemFont(ofSize: 12, weight: .bold)
        advertiserLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        advertiserLabel.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        advertiserLabel.layer.cornerRadius = 8
        advertiserLabel.clipsToBounds = true
        advertiserLabel.textAlignment = .center

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 14
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        iconImageView.layer.borderWidth = 1
        iconImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        mediaDisplayView.translatesAutoresizingMaskIntoConstraints = false
        mediaDisplayView.layer.cornerRadius = 16
        mediaDisplayView.clipsToBounds = true
        mediaDisplayView.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        mediaDisplayView.layer.borderWidth = 1
        mediaDisplayView.layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor

        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.backgroundColor = UIColor(red: 0.93, green: 0.36, blue: 0.07, alpha: 1.0)
        callToActionButton.layer.cornerRadius = 14
        callToActionButton.isUserInteractionEnabled = false

        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.axis = .vertical
        infoStack.spacing = 7
        infoStack.addArrangedSubview(sponsoredLabel)
        infoStack.addArrangedSubview(titleLabel)
        infoStack.addArrangedSubview(bodyLabel)
        infoStack.addArrangedSubview(advertiserLabel)

        topMetaStack.translatesAutoresizingMaskIntoConstraints = false
        topMetaStack.axis = .horizontal
        topMetaStack.spacing = 14
        topMetaStack.alignment = .top
        topMetaStack.addArrangedSubview(iconImageView)
        topMetaStack.addArrangedSubview(infoStack)

        addSubview(cardInsetView)
        cardInsetView.addSubview(adBadgeLabel)
        cardInsetView.addSubview(topMetaStack)
        cardInsetView.addSubview(mediaDisplayView)
        cardInsetView.addSubview(callToActionButton)

        headlineView = titleLabel
        bodyView = bodyLabel
        advertiserView = advertiserLabel
        iconView = iconImageView
        mediaView = mediaDisplayView
        callToActionView = callToActionButton

        NSLayoutConstraint.activate([
            cardInsetView.topAnchor.constraint(equalTo: topAnchor),
            cardInsetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardInsetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardInsetView.bottomAnchor.constraint(equalTo: bottomAnchor),

            adBadgeLabel.topAnchor.constraint(equalTo: cardInsetView.topAnchor, constant: 18),
            adBadgeLabel.leadingAnchor.constraint(equalTo: cardInsetView.leadingAnchor, constant: 18),
            adBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 82),
            adBadgeLabel.heightAnchor.constraint(equalToConstant: 20),

            topMetaStack.topAnchor.constraint(equalTo: adBadgeLabel.bottomAnchor, constant: 14),
            topMetaStack.leadingAnchor.constraint(equalTo: cardInsetView.leadingAnchor, constant: 18),
            topMetaStack.trailingAnchor.constraint(equalTo: cardInsetView.trailingAnchor, constant: -18),

            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            advertiserLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),

            mediaDisplayView.topAnchor.constraint(equalTo: topMetaStack.bottomAnchor, constant: 16),
            mediaDisplayView.leadingAnchor.constraint(equalTo: cardInsetView.leadingAnchor, constant: 18),
            mediaDisplayView.trailingAnchor.constraint(equalTo: cardInsetView.trailingAnchor, constant: -18),
            mediaDisplayView.heightAnchor.constraint(equalToConstant: 168),

            callToActionButton.topAnchor.constraint(equalTo: mediaDisplayView.bottomAnchor, constant: 16),
            callToActionButton.leadingAnchor.constraint(equalTo: cardInsetView.leadingAnchor, constant: 18),
            callToActionButton.trailingAnchor.constraint(equalTo: cardInsetView.trailingAnchor, constant: -18),
            callToActionButton.bottomAnchor.constraint(equalTo: cardInsetView.bottomAnchor, constant: -18),
            callToActionButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    func render(nativeAd: NativeAd) {
        titleLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
        advertiserLabel.text = paddedAdvertiserText(nativeAd.advertiser)
        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon == nil
        advertiserLabel.isHidden = nativeAd.advertiser == nil
        bodyLabel.isHidden = nativeAd.body == nil
        mediaDisplayView.mediaContent = nativeAd.mediaContent
        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        callToActionButton.isHidden = nativeAd.callToAction == nil
        self.nativeAd = nativeAd
    }

    private func paddedAdvertiserText(_ advertiser: String?) -> String? {
        guard let advertiser, !advertiser.isEmpty else { return nil }
        return "  \(advertiser)  "
    }
}

private struct NativeAdUIKitContainer: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> FastFlowNativeAdCardView {
        FastFlowNativeAdCardView()
    }

    func updateUIView(_ uiView: FastFlowNativeAdCardView, context: Context) {
        uiView.render(nativeAd: nativeAd)
    }
}

struct AdMobNativeAdView: View {
    let presentation: NativeAdPresentation
    let onUpgrade: () -> Void

    @EnvironmentObject private var monetizationRuntime: MonetizationRuntime
    @StateObject private var loader: NativeAdSlotLoader

    private let primary = Color(hex: "ec5b13")
    private let cardDark = Color(hex: "1C1C1E")

    init(presentation: NativeAdPresentation, onUpgrade: @escaping () -> Void) {
        self.presentation = presentation
        self.onUpgrade = onUpgrade
        _loader = StateObject(wrappedValue: NativeAdSlotLoader(placement: presentation.placement))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            switch loader.loadState {
            case .loaded:
                if let nativeAd = loader.nativeAd {
                    NativeAdUIKitContainer(nativeAd: nativeAd)
                        .frame(minHeight: 300)
                } else {
                    fallbackCard(text: AppL10n.string("ads.loaded_without_payload"))
                }
            case .loading, .idle:
                fallbackCard(text: AppL10n.string("ads.loading_test"))
            case .unavailable(let message):
                fallbackCard(text: message)
            }
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .task(id: presentation.mode.rawValue + "-\(monetizationRuntime.canRequestAds)") {
            loader.loadIfNeeded(mode: presentation.mode, canRequestAds: monetizationRuntime.canRequestAds)
        }
    }

    private var header: some View {
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
    }

    private func fallbackCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .frame(height: 20)
                .frame(maxWidth: 110)

            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 18)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 120, height: 14)
                }
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .frame(height: 168)
                .overlay {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(primary)
                        Text(text)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                    }
                }

            RoundedRectangle(cornerRadius: 14)
                .fill(primary.opacity(0.18))
                .frame(height: 46)
                .overlay {
                    Text(AppL10n.string("ads.loading_sponsor"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(primary)
                }

            Text(presentation.footer)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
#endif
