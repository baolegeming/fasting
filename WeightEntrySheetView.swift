import SwiftUI

struct WeightEntrySheetView: View {
    let onSave: (Double, Date) -> Void
    let onCancel: () -> Void

    @State private var weightText: String
    @State private var recordedAt: Date
    @FocusState private var isWeightFieldFocused: Bool

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "121212")
    private let cardDark = Color(hex: "1C1C1E")

    init(
        initialWeightKg: Double? = nil,
        initialDate: Date = Date(),
        onSave: @escaping (Double, Date) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onCancel = onCancel
        _recordedAt = State(initialValue: initialDate)
        if let initialWeightKg {
            _weightText = State(initialValue: String(format: "%.1f", initialWeightKg))
        } else {
            _weightText = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(AppL10n.string("weight.entry.title"))
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                            Text(AppL10n.string("weight.entry.subtitle"))
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                                .lineSpacing(3)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(AppL10n.string("weight.entry.weight"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.gray)

                                HStack(spacing: 12) {
                                    TextField(AppL10n.string("weight.entry.placeholder"), text: $weightText)
                                        .keyboardType(.decimalPad)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($isWeightFieldFocused)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(.white)

                                    Text(AppL10n.string("weight.entry.unit"))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(AppL10n.string("weight.entry.recorded_at"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.gray)

                                VStack(spacing: 12) {
                                    HStack {
                                        Text(AppL10n.string("weight.entry.date"))
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.gray)
                                        Spacer()
                                        DatePicker(
                                            "",
                                            selection: $recordedAt,
                                            displayedComponents: [.date]
                                        )
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .tint(primary)
                                        .colorScheme(.dark)
                                    }

                                    HStack {
                                        Text(AppL10n.string("weight.entry.time"))
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.gray)
                                        Spacer()
                                        DatePicker(
                                            "",
                                            selection: $recordedAt,
                                            displayedComponents: [.hourAndMinute]
                                        )
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                        .tint(primary)
                                        .colorScheme(.dark)
                                    }
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                        .padding(16)
                        .background(cardDark, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )

                        Text(AppL10n.string("weight.entry.footer"))
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                    .padding(20)
                    .padding(.bottom, 120)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.string("Close")) {
                        onCancel()
                    }
                    .foregroundStyle(.gray)
                }
            }
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button(AppL10n.string("Cancel")) {
                        onCancel()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

                    Button(AppL10n.string("Save")) {
                        guard let weightKg = parsedWeightKg else { return }
                        onSave(weightKg, recordedAt)
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(primary, in: RoundedRectangle(cornerRadius: 14))
                    .disabled(parsedWeightKg == nil)
                    .opacity(parsedWeightKg == nil ? 0.45 : 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(backgroundDark)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var parsedWeightKg: Double? {
        let normalized = weightText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard let value = Double(normalized),
              (20...300).contains(value) else {
            return nil
        }
        return value
    }
}

#Preview {
    WeightEntrySheetView(
        onSave: { _, _ in },
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
