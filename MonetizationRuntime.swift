import Foundation
import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
final class MonetizationRuntime: ObservableObject {
    @Published private(set) var canRequestAds = false
    @Published private(set) var isPrivacyOptionsRequired = false
    @Published private(set) var didInitializeAds = false
    @Published private(set) var lastConsentErrorMessage: String?

    private var hasPreparedLaunch = false

    func prepareForLaunch(adMode: AdInventoryMode) async {
        guard !hasPreparedLaunch else { return }
        hasPreparedLaunch = true

        guard adMode.isServingEnabled else { return }

        await refreshConsent(adMode: adMode)

        guard canRequestAds else { return }
        initializeAdsIfNeeded(adMode: adMode)
    }

    func refreshConsent(adMode: AdInventoryMode) async {
        #if canImport(UserMessagingPlatform)
        let parameters = RequestParameters()

        #if DEBUG
        if adMode == .test {
            let debugSettings = DebugSettings()
            parameters.debugSettings = debugSettings
        }
        #endif

        do {
            try await requestConsentInfoUpdate(parameters: parameters)
            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required

            do {
                try await ConsentForm.loadAndPresentIfRequired(from: nil)
            } catch {
                lastConsentErrorMessage = error.localizedDescription
            }

            canRequestAds = ConsentInformation.shared.canRequestAds
        } catch {
            lastConsentErrorMessage = error.localizedDescription
            canRequestAds = ConsentInformation.shared.canRequestAds
            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        }
        #else
        canRequestAds = adMode.isServingEnabled
        #endif
    }

    func presentPrivacyOptions() async {
        #if canImport(UserMessagingPlatform)
        guard isPrivacyOptionsRequired else { return }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
            canRequestAds = ConsentInformation.shared.canRequestAds
        } catch {
            lastConsentErrorMessage = error.localizedDescription
        }
        #endif
    }

    private func initializeAdsIfNeeded(adMode: AdInventoryMode) {
        #if canImport(GoogleMobileAds)
        guard !didInitializeAds else { return }
        MobileAds.shared.start()
        didInitializeAds = true
        #else
        didInitializeAds = adMode.isServingEnabled
        #endif
    }

    #if canImport(UserMessagingPlatform)
    private func requestConsentInfoUpdate(parameters: RequestParameters) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    #endif
}
