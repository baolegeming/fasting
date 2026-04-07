import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionRuntime: SubscriptionRuntime
    @EnvironmentObject private var languageStore: AppLanguageStore
    @AppStorage(FastFlowDefaultsKey.isPro) private var isPro = false

    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private let primary = Color(hex: "ec5b13")
    private let privacyURL = FastFlowLegalLinks.privacyPolicy
    private let termsURL = FastFlowLegalLinks.termsOfUse

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    headline
                    featureList
                    pricingCards
                    cta
                    legal
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .id(languageStore.language.rawValue)
            .background(Color(hex: "f8f6f6").ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.08), in: Circle())
                    }
                }
            }
            .onAppear {
                Task {
                    await subscriptionRuntime.refreshSubscriptionState()
                }
            }
            .alert(AppL10n.string("subscription.alert.title"), isPresented: $showingAlert) {
                Button(AppL10n.string("subscription.alert.ok"), role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var hero: some View {
        ZStack {
            LinearGradient(
                colors: [primary, primary.opacity(0.9), primary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Image(systemName: "crown.fill")
                .font(.system(size: 68))
                .foregroundStyle(.white)
                .padding(24)
                .background(Color.white.opacity(0.2), in: Circle())
        }
    }

    private var headline: some View {
        VStack(spacing: 6) {
            Text(AppL10n.string("paywall.title"))
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(.black)
            Text(AppL10n.string("paywall.subtitle"))
                .font(.system(size: 18))
                .foregroundStyle(.gray)
            Text(AppL10n.string("paywall.description"))
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 0) {
            paywallFeatureRow(
                title: AppL10n.string("paywall.feature.history.title"),
                detail: AppL10n.string("paywall.feature.history.body")
            )
            paywallFeatureRow(
                title: AppL10n.string("paywall.feature.ad_free.title"),
                detail: AppL10n.string("paywall.feature.ad_free.body")
            )
            paywallFeatureRow(
                title: AppL10n.string("paywall.feature.insights.title"),
                detail: AppL10n.string("paywall.feature.insights.body")
            )
            paywallFeatureRow(
                title: AppL10n.string("paywall.feature.early_access.title"),
                detail: AppL10n.string("paywall.feature.early_access.body")
            )
            paywallFeatureRow(
                title: AppL10n.string("paywall.feature.support.title"),
                detail: AppL10n.string("paywall.feature.support.body")
            )
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
    }

    private func paywallFeatureRow(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(primary)
                .padding(6)
                .background(primary.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
    }

    private var pricingCards: some View {
        VStack(spacing: 12) {
            pricingCard(
                title: localizedMonthlyTitle,
                price: subscriptionRuntime.monthlyPrice,
                suffix: AppL10n.string("subscription.price_suffix.monthly"),
                subtitle: localizedMonthlyDescription,
                selected: selectedPlan == .monthly,
                highlight: false
            ) {
                selectedPlan = .monthly
            }
            pricingCard(
                title: localizedYearlyTitle,
                price: subscriptionRuntime.yearlyPrice,
                suffix: AppL10n.string("subscription.price_suffix.yearly"),
                subtitle: localizedYearlyDescription,
                selected: selectedPlan == .yearly,
                highlight: true
            ) {
                selectedPlan = .yearly
            }
        }
    }

    private func pricingCard(
        title: String,
        price: String,
        suffix: String,
        subtitle: String,
        selected: Bool,
        highlight: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(highlight ? primary : .gray)
                    Spacer()
                    if highlight {
                        Text(AppL10n.string("paywall.badge.best_value"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(primary, in: Capsule())
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(.black)
                    Text(suffix)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.gray)
                }
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(highlight ? primary : .gray)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(highlight ? primary.opacity(0.06) : .white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? primary : Color.gray.opacity(0.25), lineWidth: selected ? 2 : 1)
            )
        }
    }

    private var cta: some View {
        VStack(spacing: 12) {
            if !subscriptionRuntime.hasLoadedOfferings {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(primary)
                    Text(AppL10n.string("subscription.offerings.loading"))
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                }
            }

            Button {
                Task {
                    await startPurchase()
                }
            } label: {
                Text(subscriptionRuntime.isPurchaseInFlight
                     ? AppL10n.string("subscription.purchase.in_progress")
                     : AppL10n.string("paywall.cta.join"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!selectedPlanAvailable || subscriptionRuntime.isPurchaseInFlight)
            .opacity((!selectedPlanAvailable || subscriptionRuntime.isPurchaseInFlight) ? 0.65 : 1)

            HStack(spacing: 6) {
                Text(AppL10n.string("paywall.cta.rollout_notice"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.gray)
                Button(AppL10n.string("paywall.cta.restore")) {
                    restorePurchase()
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.gray)
                .disabled(subscriptionRuntime.isPurchaseInFlight)
            }
        }
    }

    private var legal: some View {
        VStack(spacing: 10) {
            Text(AppL10n.string("subscription.legal.notice"))
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link(AppL10n.string("subscription.legal.privacy"), destination: privacyURL)
                Link(AppL10n.string("subscription.legal.terms"), destination: termsURL)
            }
            .font(.system(size: 13, weight: .semibold))
            .tint(primary)
        }
        .frame(maxWidth: .infinity)
    }

    private func startPurchase() async {
        let plan: SubscriptionPlan = selectedPlan == .yearly ? .yearly : .monthly
        if let message = await subscriptionRuntime.purchase(plan: plan) {
            alertMessage = message
            showingAlert = true
            return
        }

        if subscriptionRuntime.isProActive {
            isPro = true
            dismiss()
        }
    }

    private func restorePurchase() {
        Task {
            if let message = await subscriptionRuntime.restorePurchases() {
                alertMessage = message
                showingAlert = true
                return
            }

            if subscriptionRuntime.isProActive {
                isPro = true
                dismiss()
            }
        }
    }

    private var selectedPlanAvailable: Bool {
        subscriptionRuntime.isPlanAvailable(selectedPlan == .yearly ? .yearly : .monthly)
    }

    private var localizedMonthlyTitle: String {
        _ = languageStore.language
        return AppL10n.string("subscription.plan.monthly.title")
    }

    private var localizedYearlyTitle: String {
        _ = languageStore.language
        return AppL10n.string("subscription.plan.yearly.title")
    }

    private var localizedMonthlyDescription: String {
        _ = languageStore.language
        return AppL10n.string("subscription.plan.monthly.description")
    }

    private var localizedYearlyDescription: String {
        _ = languageStore.language
        return AppL10n.string("subscription.plan.yearly.description")
    }
}

private enum PaywallPlan {
    case monthly
    case yearly
}

private enum FastFlowLegalLinks {
    // Keep this in sync with the Privacy Policy URL configured in App Store Connect.
    static let privacyPolicy = URL(string: "https://fasting-nu.vercel.app/privacy")!
    static let termsOfUse = URL(string: "https://www.apple.com/legal/macapps/stdeula/")!
}

#Preview {
    PaywallView()
}
