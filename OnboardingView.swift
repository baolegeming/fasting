import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: FastFlowTimerViewModel
    @AppStorage(FastFlowDefaultsKey.onboardingCompleted) private var onboardingCompleted = false
    @AppStorage(FastFlowDefaultsKey.startReminderEnabled) private var startReminderEnabled = false
    @AppStorage(FastFlowDefaultsKey.notificationPermissionRequested) private var notificationPermissionRequested = false
    @AppStorage(FastFlowDefaultsKey.startReminderHour) private var startReminderHour = 20
    @AppStorage(FastFlowDefaultsKey.startReminderMinute) private var startReminderMinute = 0

    @State private var currentPage = 0
    @State private var selectedPlanType = PlanOption.plan16_8.type
    @State private var customFastingHours = 17
    @State private var showCustomPlanSheet = false

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "0F0F0F")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        ZStack {
            backgroundDark.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    pageOne.tag(0)
                    pageTwo.tag(1)
                    pageThree.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
        }
        .onAppear {
            syncPlanSelectionFromCurrent()
        }
        .sheet(isPresented: $showCustomPlanSheet) {
            CustomPlanSheetView(
                fastingHours: $customFastingHours,
                title: AppL10n.string("custom_plan.title"),
                onSave: {
                    selectedPlanType = PlanOption.customType
                    showCustomPlanSheet = false
                },
                onCancel: {
                    showCustomPlanSheet = false
                }
            )
        }
    }

    private var pageOne: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 58))
                .foregroundStyle(.white)
                .padding(30)
                .background(primary, in: RoundedRectangle(cornerRadius: 20))
            Text(AppL10n.string("FastFlow"))
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(.white)
            Text(AppL10n.string("通过清晰的断食节奏与阶段反馈，帮助你更稳定地坚持。"))
                .font(.system(size: 17))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            onboardingEducationCard(
                eyebrow: AppL10n.string("onboarding.why.eyebrow"),
                title: AppL10n.string("onboarding.why.title"),
                body: FastingEducationLibrary.consistencyMatters.userFacingBody
            )
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pageTwo: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(AppL10n.string("选择你的断食计划"))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
            Text(AppL10n.string("稍后可在设置中随时调整"))
                .font(.system(size: 15))
                .foregroundStyle(.gray)
            VStack(spacing: 10) {
                ForEach(PlanOption.allCases, id: \.type) { option in
                    Button {
                        selectedPlanType = option.type
                    } label: {
                        HStack {
                            Text(option.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            if selectedPlanType == option.type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(primary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPlanType == option.type ? primary.opacity(0.15) : cardDark)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedPlanType == option.type ? primary : .clear, lineWidth: 1.5)
                        )
                    }
                }

                Button {
                    selectedPlanType = PlanOption.customType
                    showCustomPlanSheet = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppL10n.string("自定义"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(AppL10n.format("onboarding.custom.current", customPlanName))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Text(customPlanName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(primary)
                            Image(systemName: selectedPlanType == PlanOption.customType ? "checkmark.circle.fill" : "slider.horizontal.3")
                                .foregroundStyle(selectedPlanType == PlanOption.customType ? primary : .gray)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPlanType == PlanOption.customType ? primary.opacity(0.15) : cardDark)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPlanType == PlanOption.customType ? primary : .clear, lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, 24)
            onboardingEducationCard(
                eyebrow: AppL10n.string("onboarding.plan.eyebrow"),
                title: AppL10n.string("onboarding.plan.title"),
                body: AppL10n.string("onboarding.plan.body")
            )
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pageThree: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(primary)
            Text(AppL10n.string("开启提醒，保持节奏"))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
            Text(AppL10n.string("授权通知后，可收到开始提醒、阶段提醒与目标前 1 小时提醒。提醒的重点是帮你把节奏固定下来，而不是逼你做更久。"))
                .font(.system(size: 15))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            onboardingEducationCard(
                eyebrow: AppL10n.string("onboarding.guide.eyebrow"),
                title: AppL10n.string("onboarding.guide.title"),
                body: AppL10n.string("onboarding.guide.body")
            )
            .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? primary : Color.white.opacity(0.18))
                        .frame(width: index == currentPage ? 22 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .frame(height: 8)

            Button(action: handlePrimaryAction) {
                Text(primaryButtonTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 34)
        .background(backgroundDark)
    }

    private var primaryButtonTitle: String {
        switch currentPage {
        case 0: return AppL10n.string("onboarding.next")
        case 1: return AppL10n.string("onboarding.continue")
        default: return AppL10n.string("onboarding.get_started")
        }
    }

    private func handlePrimaryAction() {
        switch currentPage {
        case 0:
            currentPage = 1
        case 1:
            let selectedDurationSec = selectedPlanType == PlanOption.customType
                ? customFastingHours * 3600
                : (PlanOption.option(for: selectedPlanType)?.durationSec ?? PlanOption.plan16_8.durationSec)
            viewModel.updatePlan(planType: selectedPlanType, durationSec: selectedDurationSec)
            currentPage = 2
        default:
            NotificationManager.shared.requestAuthorization { granted in
                notificationPermissionRequested = true
                startReminderEnabled = granted
                if granted {
                    NotificationManager.shared.scheduleStartReminder(
                        hour: startReminderHour,
                        minute: startReminderMinute
                    )
                }
                onboardingCompleted = true
            }
        }
    }

    private var customPlanName: String {
        PlanOption.customRatioName(durationSec: customFastingHours * 3600) ?? AppL10n.string("custom_plan.default_ratio")
    }

    private func syncPlanSelectionFromCurrent() {
        if PlanOption.isCustom(type: viewModel.targetPlanType) {
            selectedPlanType = PlanOption.customType
            customFastingHours = PlanOption.customFastingHours(for: viewModel.targetDurationSec) ?? 17
        } else {
            selectedPlanType = PlanOption.option(for: viewModel.targetPlanType)?.type ?? PlanOption.plan16_8.type
            customFastingHours = PlanOption.customFastingHours(for: viewModel.targetDurationSec) ?? 17
        }
    }

    private func onboardingEducationCard(eyebrow: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(primary)
                .tracking(0.8)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Text(body)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingView()
        .environmentObject(FastFlowTimerViewModel())
        .preferredColorScheme(.dark)
}
