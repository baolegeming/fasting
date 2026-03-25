import SwiftUI

struct FastingRecordDraft {
    let planType: String
    let targetDurationSec: Int
    let startAt: Date
    let endAt: Date
    let status: String
    let isGoalMet: Bool
    let abortReason: String?
}

private enum FastingRecordEditorMode {
    case create
    case edit
}

private enum FastingRecordOutcome: String, CaseIterable, Identifiable {
    case completed
    case notCompleted = "not_completed"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .completed:
            return AppL10n.string("Completed")
        case .notCompleted:
            return AppL10n.string("Not Completed")
        }
    }
}

struct FastingRecordEditorSheetView: View {
    private let mode: FastingRecordEditorMode
    private let record: FastingRecord?
    let onSave: (FastingRecordDraft) -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void

    @State private var selectedPlanType: String
    @State private var customFastingHours: Int
    @State private var startAt: Date
    @State private var endAt: Date
    @State private var outcome: FastingRecordOutcome
    @State private var showCustomPlanSheet = false
    @State private var showDeleteConfirmation = false

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "121212")
    private let cardDark = Color(hex: "1C1C1E")

    init(
        record: FastingRecord,
        onSave: @escaping (FastingRecordDraft) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = .edit
        self.record = record
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _selectedPlanType = State(initialValue: PlanOption.isCustom(type: record.planType) ? PlanOption.customType : record.planType)
        _customFastingHours = State(initialValue: PlanOption.customFastingHours(for: record.targetDurationSec) ?? 17)
        _startAt = State(initialValue: record.startAt)
        _endAt = State(initialValue: record.endAt ?? Date())
        _outcome = State(initialValue: FastingRecordStatus.isNotCompleted(record.status) ? .notCompleted : .completed)
    }

    init(
        initialPlanType: String,
        initialTargetDurationSec: Int,
        initialStartAt: Date,
        initialEndAt: Date,
        onSave: @escaping (FastingRecordDraft) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = .create
        self.record = nil
        self.onSave = onSave
        self.onDelete = nil
        self.onCancel = onCancel
        _selectedPlanType = State(initialValue: PlanOption.isCustom(type: initialPlanType) ? PlanOption.customType : initialPlanType)
        _customFastingHours = State(initialValue: PlanOption.customFastingHours(for: initialTargetDurationSec) ?? 17)
        _startAt = State(initialValue: initialStartAt)
        _endAt = State(initialValue: initialEndAt)
        _outcome = State(initialValue: .completed)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(mode == .edit ? AppL10n.string("Edit Fasting Record") : AppL10n.string("Add Fasting Record"))
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                            Text(mode == .edit ? AppL10n.string("record_editor.edit_subtitle") : AppL10n.string("record_editor.create_subtitle"))
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                                .lineSpacing(3)
                        }

                        settingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Plan")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.gray)

                                VStack(spacing: 10) {
                                    ForEach(PlanOption.allCases, id: \.type) { option in
                                        planButton(title: option.name, isSelected: selectedPlanType == option.type) {
                                            selectedPlanType = option.type
                                        }
                                    }

                                    planButton(
                                        title: AppL10n.format("plan.custom.current", customPlanName),
                                        isSelected: selectedPlanType == PlanOption.customType
                                    ) {
                                        selectedPlanType = PlanOption.customType
                                        showCustomPlanSheet = true
                                    }
                                }
                            }
                        }

                        settingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Outcome")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.gray)

                                Picker("Outcome", selection: $outcome) {
                                    ForEach(FastingRecordOutcome.allCases) { item in
                                        Text(item.title).tag(item)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        settingsCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Timing")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.gray)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Start")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                    DatePicker(
                                        "",
                                        selection: $startAt,
                                        in: ...Date(),
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .tint(primary)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("End")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                    DatePicker(
                                        "",
                                        selection: $endAt,
                                        in: ...Date(),
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .tint(primary)
                                }
                            }
                        }

                        settingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Summary")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.gray)
                                summaryRow(title: "Duration", value: durationText)
                                summaryRow(title: "Plan", value: currentPlanName)
                                summaryRow(title: "Goal", value: goalStatusText)
                            }
                        }

                        if mode == .edit {
                            Button("Delete Record") {
                                showDeleteConfirmation = true
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        }

                        HStack(spacing: 12) {
                            Button("Cancel") {
                                onCancel()
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

                            Button(mode == .edit ? AppL10n.string("Save") : AppL10n.string("Add Record")) {
                                onSave(currentDraft)
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(primary, in: RoundedRectangle(cornerRadius: 14))
                            .disabled(!isValid)
                            .opacity(isValid ? 1 : 0.45)
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
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
                AppL10n.string("record_editor.delete_title"),
                isPresented: $showDeleteConfirmation,
                actions: {
                    Button(AppL10n.string("Delete"), role: .destructive) {
                        onDelete?()
                    }
                    Button(AppL10n.string("Cancel"), role: .cancel) {}
                },
                message: {
                    Text(AppL10n.string("record_editor.delete_message"))
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

    private var currentPlanName: String {
        PlanOption.displayName(forType: selectedPlanType, durationSec: selectedDurationSec)
    }

    private var customPlanName: String {
        PlanOption.customRatioName(durationSec: customFastingHours * 3600) ?? AppL10n.string("custom_plan.default_ratio")
    }

    private var durationSeconds: Int {
        max(0, Int(endAt.timeIntervalSince(startAt)))
    }

    private var durationText: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private var goalStatusText: String {
        let metGoal = outcome == .completed && durationSeconds >= selectedDurationSec
        return metGoal ? AppL10n.string("record_editor.goal_met") : AppL10n.string("record_editor.below_target")
    }

    private var isValid: Bool {
        endAt > startAt
    }

    private var currentDraft: FastingRecordDraft {
        let status = outcome.rawValue
        let metGoal = outcome == .completed && durationSeconds >= selectedDurationSec
        let abortReason: String? = outcome == .notCompleted ? (record?.abortReason ?? AbortReason.other.rawValue) : nil
        return FastingRecordDraft(
            planType: selectedPlanType,
            targetDurationSec: selectedDurationSec,
            startAt: startAt,
            endAt: endAt,
            status: status,
            isGoalMet: metGoal,
            abortReason: abortReason
        )
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

    private func summaryRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    FastingRecordEditorSheetView(
        record: FastingRecord(
            planType: "16_8",
            targetDurationSec: 16 * 3600,
            startAt: Date().addingTimeInterval(-16 * 3600),
            endAt: Date(),
            status: "completed",
            isGoalMet: true
        ),
        onSave: { _ in },
        onDelete: {},
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
