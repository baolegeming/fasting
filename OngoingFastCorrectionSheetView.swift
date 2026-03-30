import SwiftUI

struct OngoingFastCorrectionSheetView: View {
    let initialStartAt: Date
    let initialPlanType: String
    let initialTargetDurationSec: Int
    let onSave: (Date, String, Int) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var selectedPlanType: String
    @State private var customFastingHours: Int
    @State private var startAt: Date
    @State private var showCustomPlanSheet = false
    @State private var showDeleteConfirmation = false

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "121212")
    private let cardDark = Color(hex: "1C1C1E")
    private let secondaryText = Color.white.opacity(0.72)
    private let tertiaryText = Color.white.opacity(0.58)

    init(
        initialStartAt: Date,
        initialPlanType: String,
        initialTargetDurationSec: Int,
        onSave: @escaping (Date, String, Int) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialStartAt = initialStartAt
        self.initialPlanType = initialPlanType
        self.initialTargetDurationSec = initialTargetDurationSec
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _selectedPlanType = State(initialValue: PlanOption.isCustom(type: initialPlanType) ? PlanOption.customType : initialPlanType)
        _customFastingHours = State(initialValue: PlanOption.customFastingHours(for: initialTargetDurationSec) ?? PlanOption.normalizedCustomFastingHours(for: initialTargetDurationSec))
        _startAt = State(initialValue: initialStartAt)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(AppL10n.string("Adjust Current Fast"))
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                            Text(AppL10n.string("ongoing_correction.subtitle"))
                                .font(.system(size: 14))
                                .foregroundStyle(secondaryText)
                                .lineSpacing(3)
                        }

                        settingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text(AppL10n.string("Current Plan"))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(secondaryText)

                                VStack(spacing: 10) {
                                    ForEach(PlanOption.allCases, id: \.type) { option in
                                        planButton(title: option.name, isSelected: selectedPlanType == option.type) {
                                            selectedPlanType = option.type
                                        }
                                    }

                                    customPlanButton {
                                        selectedPlanType = PlanOption.customType
                                        showCustomPlanSheet = true
                                    }
                                }
                            }
                        }

                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(AppL10n.string("Actual Start Time"))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(secondaryText)
                                DatePicker(
                                    "",
                                    selection: $startAt,
                                    in: ...Date(),
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(primary)
                                Text(AppL10n.string("ongoing_correction.start_time_hint"))
                                    .font(.system(size: 13))
                                    .foregroundStyle(tertiaryText)
                                    .lineSpacing(3)
                            }
                        }

                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(AppL10n.string("Why this matters"))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(secondaryText)
                                infoRow(
                                    title: AppL10n.string("Late tap"),
                                    detail: AppL10n.string("ongoing_correction.late_tap_detail")
                                )
                                infoRow(
                                    title: AppL10n.string("Accidental tap"),
                                    detail: AppL10n.string("ongoing_correction.accidental_tap_detail")
                                )
                            }
                        }

                        Button(AppL10n.string("Delete Current Session")) {
                            showDeleteConfirmation = true
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                        HStack(spacing: 12) {
                            Button(AppL10n.string("Cancel")) {
                                onCancel()
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

                            Button(AppL10n.string("Save Changes")) {
                                onSave(startAt, selectedPlanType, selectedDurationSec)
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(primary, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.string("common.close")) {
                        onCancel()
                    }
                    .foregroundStyle(.gray)
                }
            }
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            .alert(
                AppL10n.string("ongoing_correction.delete_title"),
                isPresented: $showDeleteConfirmation,
                actions: {
                    Button(AppL10n.string("Delete"), role: .destructive) {
                        onDelete()
                    }
                    Button(AppL10n.string("Cancel"), role: .cancel) {}
                },
                message: {
                    Text(AppL10n.string("ongoing_correction.delete_message"))
                }
            )
        }
    }

    private var selectedDurationSec: Int {
        if selectedPlanType == PlanOption.customType {
            return customFastingHours * 3600
        }
        return PlanOption.option(for: selectedPlanType)?.durationSec ?? PlanOption.plan16_8.durationSec
    }

    private var customPlanName: String {
        PlanOption.customRatioName(durationSec: customFastingHours * 3600) ?? AppL10n.string("custom_plan.default_ratio")
    }

    private var customPlanDescription: String {
        if let customName = PlanOption.customRatioName(durationSec: customFastingHours * 3600) {
            return AppL10n.format("ongoing_correction.custom.current_desc", customName)
        }
        return AppL10n.string("ongoing_correction.custom.default_desc")
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func planButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? primary.opacity(0.15) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? primary : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func customPlanButton(action: @escaping () -> Void) -> some View {
        let isSelected = selectedPlanType == PlanOption.customType

        return Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(AppL10n.string("custom_plan.title"))
                            .font(.system(size: 16, weight: .semibold))
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
                        .lineSpacing(3)
                }
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(primary)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? primary.opacity(0.15) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? primary : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func infoRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(secondaryText)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OngoingFastCorrectionSheetView(
        initialStartAt: Date().addingTimeInterval(-6 * 3600),
        initialPlanType: "16_8",
        initialTargetDurationSec: 16 * 3600,
        onSave: { _, _, _ in },
        onDelete: {},
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
