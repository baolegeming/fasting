import Foundation

#if canImport(RevenueCat)
import RevenueCat
#endif

enum SubscriptionPlan {
    case monthly
    case yearly
}

@MainActor
final class SubscriptionRuntime: ObservableObject {
    @Published private(set) var isConfigured = false
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchaseInFlight = false
    @Published private(set) var isProActive = false
    @Published private(set) var hasLoadedOfferings = false
    @Published private(set) var monthlyPrice = "¥25"
    @Published private(set) var yearlyPrice = "¥158"
    @Published private(set) var lastErrorMessage: String?

    #if canImport(RevenueCat)
    private var monthlyPackage: Package?
    private var yearlyPackage: Package?
    private var customerInfoTask: Task<Void, Never>?
    private var hasPreparedLaunch = false
    #endif

    init() {
        syncStoredProStatus(false)
    }

    func prepareForLaunch() async {
        #if canImport(RevenueCat)
        guard !hasPreparedLaunch else { return }
        hasPreparedLaunch = true

        guard let configuration = configuration else {
            syncStoredProStatus(false)
            return
        }

        configureIfNeeded(apiKey: configuration.apiKey)
        isConfigured = true
        startCustomerInfoListener(entitlementID: configuration.entitlementID)
        await refreshSubscriptionState()
        #else
        syncStoredProStatus(false)
        #endif
    }

    func refreshSubscriptionState() async {
        #if canImport(RevenueCat)
        guard let configuration = configuration else {
            syncStoredProStatus(false)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            apply(customerInfo: customerInfo, entitlementID: configuration.entitlementID)
            try await loadOfferings()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #endif
    }

    func purchase(plan: SubscriptionPlan) async -> String? {
        #if canImport(RevenueCat)
        guard configuration != nil else {
            return AppL10n.string("subscription.error.not_configured")
        }

        guard isPlanAvailable(plan) else {
            return hasLoadedOfferings
                ? AppL10n.string("subscription.error.package_unavailable")
                : AppL10n.string("subscription.error.offerings_loading")
        }

        let package: Package?
        switch plan {
        case .monthly:
            package = monthlyPackage
        case .yearly:
            package = yearlyPackage
        }

        guard let package else {
            return AppL10n.string("subscription.error.package_unavailable")
        }

        isPurchaseInFlight = true
        defer { isPurchaseInFlight = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            guard let entitlementID = configuration?.entitlementID else {
                return AppL10n.string("subscription.error.entitlement_missing")
            }

            apply(customerInfo: result.customerInfo, entitlementID: entitlementID)
            if !isProActive {
                return AppL10n.string("subscription.error.entitlement_inactive")
            }
            return nil
        } catch {
            lastErrorMessage = error.localizedDescription
            return AppL10n.string("subscription.error.purchase_failed")
        }
        #else
        return AppL10n.string("subscription.error.sdk_missing")
        #endif
    }

    func restorePurchases() async -> String? {
        #if canImport(RevenueCat)
        guard let configuration = configuration else {
            return AppL10n.string("subscription.error.not_configured")
        }

        isPurchaseInFlight = true
        defer { isPurchaseInFlight = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            apply(customerInfo: customerInfo, entitlementID: configuration.entitlementID)
            return isProActive ? nil : AppL10n.string("subscription.error.no_restorable_purchase")
        } catch {
            lastErrorMessage = error.localizedDescription
            return AppL10n.string("subscription.error.restore_failed")
        }
        #else
        return AppL10n.string("subscription.error.sdk_missing")
        #endif
    }

    #if canImport(RevenueCat)
    func isPlanAvailable(_ plan: SubscriptionPlan) -> Bool {
        switch plan {
        case .monthly:
            return monthlyPackage != nil
        case .yearly:
            return yearlyPackage != nil
        }
    }

    deinit {
        customerInfoTask?.cancel()
    }

    private struct Configuration {
        let apiKey: String
        let entitlementID: String
    }

    private var configuration: Configuration? {
        let bundle = Bundle.main
        let apiKey = (bundle.object(forInfoDictionaryKey: "FastFlowRevenueCatAPIKey") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let entitlementID = (bundle.object(forInfoDictionaryKey: "FastFlowRevenueCatEntitlementID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !apiKey.isEmpty, !entitlementID.isEmpty else {
            return nil
        }

        return Configuration(apiKey: apiKey, entitlementID: entitlementID)
    }

    private func configureIfNeeded(apiKey: String) {
        guard !Purchases.isConfigured else { return }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: apiKey)
    }

    private func startCustomerInfoListener(entitlementID: String) {
        guard customerInfoTask == nil else { return }
        customerInfoTask = Task { [weak self] in
            guard let self else { return }
            for await customerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run {
                    self.apply(customerInfo: customerInfo, entitlementID: entitlementID)
                }
            }
        }
    }

    private func loadOfferings() async throws {
        hasLoadedOfferings = false
        let offerings = try await Purchases.shared.offerings()
        guard let current = offerings.current else {
            monthlyPackage = nil
            yearlyPackage = nil
            hasLoadedOfferings = true
            return
        }

        monthlyPackage = current.monthly
        yearlyPackage = current.annual

        if let monthlyPackage {
            monthlyPrice = monthlyPackage.storeProduct.localizedPriceString
        }
        if let yearlyPackage {
            yearlyPrice = yearlyPackage.storeProduct.localizedPriceString
        }
        hasLoadedOfferings = true
    }

    private func apply(customerInfo: CustomerInfo, entitlementID: String) {
        let isActive = customerInfo.entitlements.active[entitlementID] != nil
        isProActive = isActive
        syncStoredProStatus(isActive)
    }
    #endif

    private func syncStoredProStatus(_ isActive: Bool) {
        isProActive = isActive
        UserDefaults.standard.set(isActive, forKey: FastFlowDefaultsKey.isPro)
    }
}
