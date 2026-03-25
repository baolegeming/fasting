import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionRuntime: SubscriptionRuntime
    @AppStorage(FastFlowDefaultsKey.isPro) private var isPro = false

    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private let primary = Color(hex: "ec5b13")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    headline
                    featureList
                    pricingCards
                    cta
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
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
            .alert("购买提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) {}
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
            Text(AppL10n.string("FastFlow Pro"))
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(.black)
            Text(AppL10n.string("为长期复盘和更深一层的断食洞察做准备"))
                .font(.system(size: 18))
                .foregroundStyle(.gray)
            Text(AppL10n.string("当前核心计时与完整历史保持可用，Pro 会聚焦更深一层的复盘、洞察与后续高级能力。"))
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
                title: AppL10n.string("Advanced history filters"),
                detail: AppL10n.string("按时间、计划、结果和提前结束原因快速筛选历史记录。")
            )
            paywallFeatureRow(
                title: AppL10n.string("Ad-free experience"),
                detail: AppL10n.string("移除 History 和 Insights 中的广告位，保留更专注的使用体验。")
            )
            paywallFeatureRow(
                title: AppL10n.string("Advanced insights"),
                detail: AppL10n.string("更深一层的趋势、相关性和行为洞察会优先进入 Pro。")
            )
            paywallFeatureRow(
                title: AppL10n.string("Early access to new Pro tools"),
                detail: AppL10n.string("高级历史筛选和后续更深的复盘工具会逐步进入 Pro。")
            )
            paywallFeatureRow(
                title: AppL10n.string("Support FastFlow"),
                detail: AppL10n.string("帮助我们把 FastFlow 打磨成更好的轻断食陪伴产品。")
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
                title: AppL10n.string("Monthly"),
                price: subscriptionRuntime.monthlyPrice,
                suffix: "/mo",
                subtitle: AppL10n.string("Flexible billing"),
                selected: selectedPlan == .monthly,
                highlight: false
            ) {
                selectedPlan = .monthly
            }
            pricingCard(
                title: AppL10n.string("Yearly"),
                price: subscriptionRuntime.yearlyPrice,
                suffix: "/yr",
                subtitle: AppL10n.string("Lower annual cost"),
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
                    Text(title.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(highlight ? primary : .gray)
                    Spacer()
                    if highlight {
                        Text(AppL10n.string("BEST VALUE"))
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
            Button {
                Task {
                    await startPurchase()
                }
            } label: {
                Text(AppL10n.string("加入 FastFlow Pro"))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(primary, in: RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 6) {
                Text(AppL10n.string("部分 Pro 能力会随版本逐步开放 ·"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.gray)
                Button(AppL10n.string("恢复购买")) {
                    restorePurchase()
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.gray)
            }
        }
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
}

private enum PaywallPlan {
    case monthly
    case yearly
}

#Preview {
    PaywallView()
}
