import Foundation

enum AdInventoryMode: String, CaseIterable, Identifiable {
    case disabled
    case test
    case live

    var id: String { rawValue }

    var title: String {
        switch self {
        case .disabled:
            return "Ads Off"
        case .test:
            return "Test Ads"
        case .live:
            return "Live Ads"
        }
    }

    var badgeText: String {
        switch self {
        case .disabled:
            return "ADS OFF"
        case .test:
            return "TEST AD"
        case .live:
            return "SPONSORED"
        }
    }

    var runtimeNote: String {
        switch self {
        case .disabled:
            return "This slot is disabled for this build."
        case .test:
            return "Safe internal placement for QA. Do not ship live traffic from test mode."
        case .live:
            return "Production slot reserved for SDK-backed native ads."
        }
    }

    var isServingEnabled: Bool {
        self != .disabled
    }

    static var buildFallbackDefault: AdInventoryMode {
        #if DEBUG
        return .test
        #else
        return .disabled
        #endif
    }

    static func resolved(from rawValue: String?) -> AdInventoryMode {
        guard let rawValue, let mode = AdInventoryMode(rawValue: rawValue) else {
            return buildFallbackDefault
        }
        return mode
    }
}

enum AdPlacement: String, CaseIterable, Identifiable {
    case historyNative
    case insightsNative

    var id: String { rawValue }

    var headline: String {
        switch self {
        case .historyNative:
            return "History sponsor slot"
        case .insightsNative:
            return "Insights sponsor slot"
        }
    }

    var detail: String {
        switch self {
        case .historyNative:
            return "Keep this placement below the main record flow so it does not interfere with reviewing fasting sessions."
        case .insightsNative:
            return "Keep this placement in the lower half of Insights so the main charts and weekly report stay uninterrupted."
        }
    }
}

struct NativeAdPresentation: Equatable {
    let placement: AdPlacement
    let mode: AdInventoryMode
    let headline: String
    let detail: String
    let footer: String
}

enum MonetizationPolicy {
    private enum InfoKey {
        static let adInventoryDefaultMode = "FastFlowAdInventoryDefaultMode"
        static let historyNativeAdUnitID = "FastFlowHistoryNativeAdUnitID"
        static let insightsNativeAdUnitID = "FastFlowInsightsNativeAdUnitID"
    }

    static let sampleAdMobAppID = "ca-app-pub-3940256099942544~1458002511"
    static let sampleNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"

    static func defaultAdMode(bundle: Bundle = .main) -> AdInventoryMode {
        if let configuredMode = bundle.object(forInfoDictionaryKey: InfoKey.adInventoryDefaultMode) as? String,
           let mode = AdInventoryMode(rawValue: configuredMode) {
            if mode == .live, !hasLiveInventory(bundle: bundle) {
                return .disabled
            }
            return mode
        }

        if hasLiveInventory(bundle: bundle) {
            return .live
        }

        return AdInventoryMode.buildFallbackDefault
    }

    static func adMode(from rawValue: String?, bundle: Bundle = .main) -> AdInventoryMode {
        guard let rawValue else {
            return defaultAdMode(bundle: bundle)
        }

        let resolved = AdInventoryMode.resolved(from: rawValue)
        if resolved == .live, !hasLiveInventory(bundle: bundle) {
            return .disabled
        }
        return resolved
    }

    static func shouldShowAds(isPro: Bool, adMode: AdInventoryMode) -> Bool {
        !isPro && adMode.isServingEnabled
    }

    static func nativePlacement(
        for placement: AdPlacement,
        isPro: Bool,
        rawAdMode: String?,
        bundle: Bundle = .main
    ) -> NativeAdPresentation? {
        let adMode = adMode(from: rawAdMode, bundle: bundle)
        guard shouldShowAds(isPro: isPro, adMode: adMode) else {
            return nil
        }

        return NativeAdPresentation(
            placement: placement,
            mode: adMode,
            headline: placement.headline,
            detail: placement.detail,
            footer: "Upgrade to Pro to remove ads from FastFlow."
        )
    }

    static func nativeAdUnitID(
        for placement: AdPlacement,
        adMode: AdInventoryMode,
        bundle: Bundle = .main
    ) -> String? {
        switch adMode {
        case .disabled:
            return nil
        case .test:
            return sampleNativeAdUnitID
        case .live:
            return configuredLiveAdUnitID(for: placement, bundle: bundle)
        }
    }

    static func hasLiveInventory(bundle: Bundle = .main) -> Bool {
        guard let appID = bundle.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String else {
            return false
        }

        guard isRealAdMobIdentifier(appID, sampleValue: sampleAdMobAppID) else {
            return false
        }

        return AdPlacement.allCases.allSatisfy { placement in
            configuredLiveAdUnitID(for: placement, bundle: bundle) != nil
        }
    }

    private static func configuredLiveAdUnitID(
        for placement: AdPlacement,
        bundle: Bundle
    ) -> String? {
        let key: String
        switch placement {
        case .historyNative:
            key = InfoKey.historyNativeAdUnitID
        case .insightsNative:
            key = InfoKey.insightsNativeAdUnitID
        }

        guard let rawValue = bundle.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        return sanitizedIdentifier(rawValue, sampleValue: sampleNativeAdUnitID)
    }

    private static func isRealAdMobIdentifier(_ value: String, sampleValue: String) -> Bool {
        sanitizedIdentifier(value, sampleValue: sampleValue) != nil
    }

    private static func sanitizedIdentifier(_ value: String, sampleValue: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != sampleValue else {
            return nil
        }
        return trimmed
    }
}
