import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: FastFlowTimerViewModel
    @EnvironmentObject private var monetizationRuntime: MonetizationRuntime
    @EnvironmentObject private var subscriptionRuntime: SubscriptionRuntime
    @EnvironmentObject private var languageStore: AppLanguageStore

    @AppStorage(FastFlowDefaultsKey.startReminderEnabled) private var startReminderEnabled = false
    @AppStorage(FastFlowDefaultsKey.phasePushEnabled) private var phasePushEnabled = true
    @AppStorage(FastFlowDefaultsKey.oneHourPushEnabled) private var oneHourPushEnabled = true
    @AppStorage(FastFlowDefaultsKey.startReminderHour) private var startReminderHour = 20
    @AppStorage(FastFlowDefaultsKey.startReminderMinute) private var startReminderMinute = 0
    @AppStorage(FastFlowDefaultsKey.isPro) private var isPro = false
    @AppStorage(FastFlowDefaultsKey.adInventoryMode) private var adInventoryModeRaw = AdInventoryMode.buildFallbackDefault.rawValue
    @AppStorage(FastFlowDefaultsKey.notificationPermissionRequested) private var notificationPermissionRequested = false

    @State private var showPlanPicker = false
    @State private var showPaywall = false
    @State private var showReminderTimePicker = false
    @State private var showCustomPlanSheet = false
    @State private var showLanguagePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var reminderTime = Date()
    @State private var customFastingHours = 17

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "0F0F0F")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionLabel("Plan")
                    settingsCard {
                        planRow
                        divider
                        startReminderRow
                        divider
                        reminderTimeRow
                    }

                    sectionLabel("Notifications")
                    settingsCard {
                        toggleRow(icon: "chart.line.uptrend.xyaxis", title: "Phase Milestone Alerts", isOn: $phasePushEnabled)
                        divider
                        toggleRow(icon: "hourglass.bottomhalf.filled", title: "1 Hour Remaining", isOn: $oneHourPushEnabled)
                    }

                    sectionLabel("Subscription")
                    settingsCard {
                        subscriptionStatusRow
                        divider
                        restorePurchaseRow
                    }

                    #if DEBUG
                    sectionLabel("Developer")
                    settingsCard {
                        adModeRow
                    }
                    #endif

                    sectionLabel("Data Management")
                    settingsCard {
                        backupRow
                        divider
                        backupNowRow
                    }

                    if monetizationRuntime.isPrivacyOptionsRequired {
                        sectionLabel("Privacy")
                        settingsCard {
                            privacyChoicesRow
                        }
                    }

                    sectionLabel("Language")
                    settingsCard {
                        languageRow
                    }

                    sectionLabel("About")
                    settingsCard {
                        versionRow
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(backgroundDark.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showPlanPicker) {
                PlanSelectionSheetView(
                    selectedPlanType: viewModel.targetPlanType,
                    selectedDurationSec: viewModel.targetDurationSec,
                    onSelectPreset: { option in
                        viewModel.updatePlan(planType: option.type, durationSec: option.durationSec)
                        showPlanPicker = false
                    },
                    onSelectCustom: {
                        syncCustomPlanState()
                        showPlanPicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showCustomPlanSheet = true
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguageSelectionSheetView(
                    selectedLanguage: languageStore.language,
                    onSelect: { language in
                        languageStore.setLanguage(language)
                        showLanguagePicker = false
                    }
                )
                .presentationDetents([.fraction(0.32)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showReminderTimePicker) {
                reminderTimeSheet
            }
            .sheet(isPresented: $showCustomPlanSheet) {
                CustomPlanSheetView(
                    fastingHours: $customFastingHours,
                    title: "自定义计划",
                    onSave: {
                        viewModel.updatePlan(
                            planType: PlanOption.customType,
                            durationSec: customFastingHours * 3600
                        )
                        showCustomPlanSheet = false
                    },
                    onCancel: {
                        showCustomPlanSheet = false
                    }
                )
            }
            .onAppear {
                syncReminderTime()
                syncCustomPlanState()
            }
            .onChange(of: startReminderEnabled) { _, newValue in
                handleStartReminderChange(newValue)
            }
            .onChange(of: phasePushEnabled) { _, _ in
                viewModel.refreshScheduledNotifications()
            }
            .onChange(of: oneHourPushEnabled) { _, _ in
                viewModel.refreshScheduledNotifications()
            }
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var planRow: some View {
        Button {
            showPlanPicker = true
        } label: {
            HStack {
                rowTitle(icon: "timer", title: "Current Plan")
                Spacer()
                HStack(spacing: 4) {
                    Text(currentPlanName)
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var startReminderRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                rowTitle(icon: "bell", title: "Start Reminder")
                Text(AppL10n.format("Daily at %02d:%02d", startReminderHour, startReminderMinute))
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .padding(.leading, 30)
            }
            Spacer()
            Toggle("", isOn: $startReminderEnabled)
                .tint(primary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var reminderTimeRow: some View {
        Button {
            syncReminderTime()
            showReminderTimePicker = true
        } label: {
            HStack {
                rowTitle(icon: "clock", title: "Reminder Time")
                Spacer()
                HStack(spacing: 4) {
                    Text(String(format: "%02d:%02d", startReminderHour, startReminderMinute))
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private func toggleRow(icon: String, title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        HStack {
            rowTitle(icon: icon, title: title)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(primary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var subscriptionStatusRow: some View {
        HStack {
            rowTitle(icon: "star.fill", title: "Subscription Status")
            Spacer()
            if isPro {
                Text("Pro · Active")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.15), in: Capsule())
            } else {
                Button("升级 Pro →") {
                    showPaywall = true
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(primary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var restorePurchaseRow: some View {
        Button {
            restorePurchase()
        } label: {
            HStack {
                rowTitle(icon: "arrow.triangle.2.circlepath", title: "Restore Purchase")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.gray.opacity(0.6))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var privacyChoicesRow: some View {
        Button {
            Task {
                await monetizationRuntime.presentPrivacyOptions()
            }
        } label: {
            HStack {
                rowTitle(icon: "hand.raised", title: "Privacy Choices")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.gray.opacity(0.6))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var backupRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            rowTitle(icon: "icloud", title: "iCloud Backup")
            Text("即将支持，当前版本暂未接入云备份。")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .padding(.leading, 30)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var backupNowRow: some View {
        Button {
            alertMessage = AppL10n.string("iCloud 备份功能还在开发中，当前版本暂不支持手动备份。")
            showAlert = true
        } label: {
            HStack {
                rowTitle(icon: "icloud.and.arrow.up", title: "Backup Now")
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var languageRow: some View {
        Button {
            showLanguagePicker = true
        } label: {
            HStack {
                rowTitle(icon: "globe", title: "App Language")
                Spacer()
                HStack(spacing: 4) {
                    Text(languageStore.language.displayName)
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var versionRow: some View {
        HStack {
            rowTitle(icon: "info.circle", title: "Version")
            Spacer()
            Text(versionText)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private func rowTitle(icon: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(primary)
                .frame(width: 22)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    #if DEBUG
    private var adModeRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            rowTitle(icon: "megaphone", title: "Ad Inventory Mode")

            Picker("Ad Inventory Mode", selection: $adInventoryModeRaw) {
                ForEach(AdInventoryMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)

            Text("Debug builds default to Test Ads. Release builds follow bundle ad configuration and stay off until live inventory is fully configured.")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }
    #endif

    private var reminderTimeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(
                    "提醒时间",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button("保存") {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                    startReminderHour = components.hour ?? 20
                    startReminderMinute = components.minute ?? 0
                    if startReminderEnabled {
                        NotificationManager.shared.scheduleStartReminder(
                            hour: startReminderHour,
                            minute: startReminderMinute
                        )
                    }
                    showReminderTimePicker = false
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        showReminderTimePicker = false
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.38)])
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(cardDark, in: RoundedRectangle(cornerRadius: 12))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }

    private func sectionLabel(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.gray)
            .tracking(0.8)
            .textCase(.uppercase)
    }

    private var currentPlanName: String {
        PlanOption.displayName(
            forType: viewModel.targetPlanType,
            durationSec: viewModel.targetDurationSec
        )
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func restorePurchase() {
        Task {
            if let message = await subscriptionRuntime.restorePurchases() {
                alertMessage = message
                showAlert = true
                return
            }

            alertMessage = AppL10n.string("恢复购买成功。")
            showAlert = true
        }
    }

    private func syncReminderTime() {
        let calendar = Calendar.current
        let now = Date()
        reminderTime = calendar.date(
            bySettingHour: startReminderHour,
            minute: startReminderMinute,
            second: 0,
            of: now
        ) ?? now
    }

    private func syncCustomPlanState() {
        customFastingHours = PlanOption.customFastingHours(for: viewModel.targetDurationSec) ?? 17
    }

    private func handleStartReminderChange(_ newValue: Bool) {
        if newValue {
            NotificationManager.shared.getAuthorizationStatus { status in
                switch status {
                case .authorized, .provisional, .ephemeral:
                    notificationPermissionRequested = true
                    NotificationManager.shared.scheduleStartReminder(
                        hour: startReminderHour,
                        minute: startReminderMinute
                    )
                case .notDetermined:
                    NotificationManager.shared.requestAuthorization { granted in
                        notificationPermissionRequested = true
                        if granted {
                            NotificationManager.shared.scheduleStartReminder(
                                hour: startReminderHour,
                                minute: startReminderMinute
                            )
                        } else {
                            startReminderEnabled = false
                            alertMessage = AppL10n.string("通知权限未开启，请在系统设置中允许通知。")
                            showAlert = true
                        }
                    }
                case .denied:
                    notificationPermissionRequested = true
                    startReminderEnabled = false
                    alertMessage = AppL10n.string("通知权限未开启，请在系统设置中允许通知。")
                    showAlert = true
                @unknown default:
                    startReminderEnabled = false
                    alertMessage = AppL10n.string("暂时无法确认通知权限状态，请稍后重试。")
                    showAlert = true
                }
            }
        } else {
            NotificationManager.shared.cancelStartReminder()
        }
    }
}

private struct PlanSelectionSheetView: View {
    let selectedPlanType: String
    let selectedDurationSec: Int
    let onSelectPreset: (PlanOption) -> Void
    let onSelectCustom: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "0F0F0F")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pick the fasting rhythm that feels most sustainable this week.")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)

                    ForEach(PlanOption.allCases, id: \.type) { option in
                        planRow(option)
                    }

                    customPlanRow
                }
                .padding(20)
            }
            .background(backgroundDark.ignoresSafeArea())
            .navigationTitle("当前计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func planRow(_ option: PlanOption) -> some View {
        let isSelected = selectedPlanType == option.type

        return Button {
            onSelectPreset(option)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(option.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(primary)
                        }
                    }
                    Text(optionDescription(option))
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? primary : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var customPlanRow: some View {
        let isSelected = PlanOption.isCustom(type: selectedPlanType)

        return Button {
            onSelectCustom()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("自定义计划")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(primary)
                        }
                    }
                    Text(customPlanDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(primary)
                    .padding(.top, 4)
            }
            .padding(16)
            .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? primary : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func optionDescription(_ option: PlanOption) -> String {
        switch option {
        case .plan16_8:
            return "适合大多数人，容易开始，也更容易长期坚持。"
        case .plan18_6:
            return "在稳定节奏上再进一小步，适合已经习惯 16:8 的用户。"
        case .plan20_4:
            return "进食窗口更短，适合已经有较稳定断食习惯的人。"
        case .omad:
            return "一天一餐，节奏更激进，建议在熟悉断食后再尝试。"
        }
    }

    private var customPlanDescription: String {
        if let customName = PlanOption.customRatioName(durationSec: selectedDurationSec),
           PlanOption.isCustom(type: selectedPlanType) {
            return "当前为 \(customName)，适合按你的真实生活节奏来设定。"
        }
        return "按你自己的节奏设置 fasting 时长，更灵活也更贴合真实作息。"
    }
}

private struct LanguageSelectionSheetView: View {
    let selectedLanguage: AppLanguage
    let onSelect: (AppLanguage) -> Void

    @Environment(\.dismiss) private var dismiss

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "0F0F0F")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Choose the app language used across the main product experience.")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)

                ForEach(AppLanguage.allCases) { language in
                    Button {
                        onSelect(language)
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            if selectedLanguage == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(primary)
                            }
                        }
                        .padding(16)
                        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedLanguage == language ? primary : Color.white.opacity(0.08), lineWidth: selectedLanguage == language ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(backgroundDark.ignoresSafeArea())
            .navigationTitle("应用语言")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(FastFlowTimerViewModel())
        .preferredColorScheme(.dark)
}
