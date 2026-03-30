import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: FastFlowTimerViewModel
    @EnvironmentObject private var syncedPreferencesStore: SyncedPreferencesStore
    @EnvironmentObject private var monetizationRuntime: MonetizationRuntime
    @EnvironmentObject private var subscriptionRuntime: SubscriptionRuntime
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var cloudSyncRuntime: CloudSyncRuntime

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
                    sectionLabel(AppL10n.string("settings.section.plan"))
                    settingsCard {
                        planRow
                        divider
                        startReminderRow
                        divider
                        reminderTimeRow
                    }

                    sectionLabel(AppL10n.string("settings.section.notifications"))
                    settingsCard {
                        toggleRow(icon: "chart.line.uptrend.xyaxis", title: AppL10n.string("settings.notifications.phase_alerts"), isOn: phasePushBinding)
                        divider
                        toggleRow(icon: "hourglass.bottomhalf.filled", title: AppL10n.string("settings.notifications.one_hour_remaining"), isOn: oneHourPushBinding)
                    }

                    sectionLabel(AppL10n.string("settings.section.subscription"))
                    settingsCard {
                        subscriptionStatusRow
                        divider
                        restorePurchaseRow
                    }

                    #if DEBUG
                    sectionLabel(AppL10n.string("settings.section.developer"))
                    settingsCard {
                        adModeRow
                    }
                    #endif

                    sectionLabel(AppL10n.string("settings.section.data_management"))
                    settingsCard {
                        backupRow
                        divider
                        backupNowRow
                    }

                    if monetizationRuntime.isPrivacyOptionsRequired {
                        sectionLabel(AppL10n.string("settings.section.privacy"))
                        settingsCard {
                            privacyChoicesRow
                        }
                    }

                    sectionLabel(AppL10n.string("settings.section.language"))
                    settingsCard {
                        languageRow
                    }

                    sectionLabel(AppL10n.string("settings.section.about"))
                    settingsCard {
                        versionRow
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(backgroundDark.ignoresSafeArea())
            .navigationTitle(AppL10n.string("settings.title"))
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
                    title: AppL10n.string("custom_plan.title"),
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
            .alert(AppL10n.string("settings.alert.notice"), isPresented: $showAlert) {
                Button(AppL10n.string("settings.alert.ok"), role: .cancel) {}
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
                rowTitle(icon: "timer", title: AppL10n.string("settings.current_plan"))
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
                rowTitle(icon: "bell", title: AppL10n.string("settings.start_reminder"))
                Text(AppL10n.format("settings.start_reminder.detail", syncedPreferencesStore.startReminderHour, syncedPreferencesStore.startReminderMinute))
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .padding(.leading, 30)
            }
            Spacer()
            Toggle("", isOn: startReminderBinding)
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
                rowTitle(icon: "clock", title: AppL10n.string("settings.reminder_time"))
                Spacer()
                HStack(spacing: 4) {
                    Text(String(format: "%02d:%02d", syncedPreferencesStore.startReminderHour, syncedPreferencesStore.startReminderMinute))
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

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
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
            rowTitle(icon: "star.fill", title: AppL10n.string("settings.subscription_status"))
            Spacer()
            if isPro {
                Text(AppL10n.string("settings.subscription_status.active"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.15), in: Capsule())
            } else {
                Button(AppL10n.string("settings.subscription_status.upgrade")) {
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
                rowTitle(icon: "arrow.triangle.2.circlepath", title: AppL10n.string("settings.restore_purchases"))
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
                rowTitle(icon: "hand.raised", title: AppL10n.string("settings.privacy_choices"))
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
            rowTitle(icon: "icloud", title: AppL10n.string("settings.icloud_sync"))
            Text(cloudSyncRuntime.isCloudSyncEnabled
                 ? AppL10n.string("icloud.sync.enabled.detail")
                 : AppL10n.string("icloud.sync.local_only.detail"))
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .padding(.leading, 30)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private var backupNowRow: some View {
        Button {
            alertMessage = cloudSyncRuntime.isCloudSyncEnabled
                ? AppL10n.string("icloud.sync.enabled.alert")
                : AppL10n.format(
                    "icloud.sync.local_only.alert",
                    cloudSyncRuntime.lastErrorDescription ?? AppL10n.string("icloud.sync.local_only.reason.unknown")
                )
            showAlert = true
        } label: {
            HStack {
                rowTitle(
                    icon: cloudSyncRuntime.isCloudSyncEnabled ? "arrow.triangle.2.circlepath.icloud" : "exclamationmark.icloud",
                    title: AppL10n.string("settings.sync_status")
                )
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
                rowTitle(icon: "globe", title: AppL10n.string("settings.app_language"))
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
            rowTitle(icon: "info.circle", title: AppL10n.string("settings.version"))
            Spacer()
            Text(versionText)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    private func rowTitle(icon: String, title: String) -> some View {
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
            rowTitle(icon: "megaphone", title: AppL10n.string("settings.ad_inventory_mode"))

            Picker(AppL10n.string("settings.ad_inventory_mode"), selection: $adInventoryModeRaw) {
                ForEach(AdInventoryMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)

            Text(AppL10n.string("settings.ad_inventory_mode.detail"))
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
                    AppL10n.string("settings.reminder_time"),
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button(AppL10n.string("common.save")) {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                    let hour = components.hour ?? 20
                    let minute = components.minute ?? 0
                    syncedPreferencesStore.setReminderTime(hour: hour, minute: minute)
                    if syncedPreferencesStore.startReminderEnabled {
                        NotificationManager.shared.scheduleStartReminder(
                            hour: hour,
                            minute: minute
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
            .navigationTitle(AppL10n.string("settings.reminder_time"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(AppL10n.string("common.cancel")) {
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.gray)
            .tracking(0.8)
            .textCase(.uppercase)
    }

    private var currentPlanName: String {
        if PlanOption.isCustom(type: viewModel.targetPlanType) {
            let ratioName = PlanOption.customRatioName(durationSec: viewModel.targetDurationSec)
                ?? "\(PlanOption.normalizedCustomFastingHours(for: viewModel.targetDurationSec)):\(max(24 - PlanOption.normalizedCustomFastingHours(for: viewModel.targetDurationSec), 0))"
            return AppL10n.format("plan.custom.current", ratioName)
        }

        return PlanOption.displayName(
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
            bySettingHour: syncedPreferencesStore.startReminderHour,
            minute: syncedPreferencesStore.startReminderMinute,
            second: 0,
            of: now
        ) ?? now
    }

    private func syncCustomPlanState() {
        customFastingHours = PlanOption.customFastingHours(for: viewModel.targetDurationSec) ?? PlanOption.normalizedCustomFastingHours(for: viewModel.targetDurationSec)
    }

    private func handleStartReminderChange(_ newValue: Bool) {
        if newValue {
            NotificationManager.shared.getAuthorizationStatus { status in
                switch status {
                case .authorized, .provisional, .ephemeral:
                    notificationPermissionRequested = true
                    syncedPreferencesStore.setStartReminderEnabled(true)
                    NotificationManager.shared.scheduleStartReminder(
                        hour: syncedPreferencesStore.startReminderHour,
                        minute: syncedPreferencesStore.startReminderMinute
                    )
                case .notDetermined:
                    NotificationManager.shared.requestAuthorization { granted in
                        notificationPermissionRequested = true
                        if granted {
                            syncedPreferencesStore.setStartReminderEnabled(true)
                            NotificationManager.shared.scheduleStartReminder(
                                hour: syncedPreferencesStore.startReminderHour,
                                minute: syncedPreferencesStore.startReminderMinute
                            )
                        } else {
                            syncedPreferencesStore.setStartReminderEnabled(false)
                            alertMessage = AppL10n.string("通知权限未开启，请在系统设置中允许通知。")
                            showAlert = true
                        }
                    }
                case .denied:
                    notificationPermissionRequested = true
                    syncedPreferencesStore.setStartReminderEnabled(false)
                    alertMessage = AppL10n.string("通知权限未开启，请在系统设置中允许通知。")
                    showAlert = true
                @unknown default:
                    syncedPreferencesStore.setStartReminderEnabled(false)
                    alertMessage = AppL10n.string("暂时无法确认通知权限状态，请稍后重试。")
                    showAlert = true
                }
            }
        } else {
            syncedPreferencesStore.setStartReminderEnabled(false)
            NotificationManager.shared.cancelStartReminder()
        }
    }

    private var startReminderBinding: Binding<Bool> {
        Binding(
            get: { syncedPreferencesStore.startReminderEnabled },
            set: { handleStartReminderChange($0) }
        )
    }

    private var phasePushBinding: Binding<Bool> {
        Binding(
            get: { syncedPreferencesStore.phasePushEnabled },
            set: { newValue in
                syncedPreferencesStore.setPhasePushEnabled(newValue)
                viewModel.refreshScheduledNotifications()
            }
        )
    }

    private var oneHourPushBinding: Binding<Bool> {
        Binding(
            get: { syncedPreferencesStore.oneHourPushEnabled },
            set: { newValue in
                syncedPreferencesStore.setOneHourPushEnabled(newValue)
                viewModel.refreshScheduledNotifications()
            }
        )
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
    private let secondaryText = Color.white.opacity(0.74)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(AppL10n.string("settings.plan_picker.subtitle"))
                        .font(.system(size: 14))
                        .foregroundStyle(secondaryText)

                    ForEach(PlanOption.allCases, id: \.type) { option in
                        planRow(option)
                    }

                    customPlanRow
                }
                .padding(20)
            }
            .background(backgroundDark.ignoresSafeArea())
            .navigationTitle(AppL10n.string("settings.current_plan"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.string("common.close")) {
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
                        .foregroundStyle(secondaryText)
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
                        Text(AppL10n.string("settings.plan.custom_title"))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(primary)
                        }
                    }
                    Text(customPlanDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(secondaryText)
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
            return AppL10n.string("settings.plan.desc.16_8")
        case .plan18_6:
            return AppL10n.string("settings.plan.desc.18_6")
        case .plan20_4:
            return AppL10n.string("settings.plan.desc.20_4")
        case .omad:
            return AppL10n.string("settings.plan.desc.omad")
        }
    }

    private var customPlanDescription: String {
        if let customName = PlanOption.customRatioName(durationSec: selectedDurationSec),
           PlanOption.isCustom(type: selectedPlanType) {
            return AppL10n.format("settings.plan.custom.current_desc", customName)
        }
        return AppL10n.string("settings.plan.custom.default_desc")
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
                Text(AppL10n.string("settings.language_picker.subtitle"))
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
            .navigationTitle(AppL10n.string("settings.app_language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.string("common.close")) {
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
