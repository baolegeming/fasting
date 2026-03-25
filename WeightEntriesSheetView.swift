import SwiftUI

struct WeightEntriesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var weightStore: WeightStore

    @State private var showAddSheet = false
    @State private var editingEntry: WeightEntry?
    @State private var deletingEntry: WeightEntry?

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "121212")
    private let cardDark = Color(hex: "1C1C1E")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()

                if sortedEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 34))
                            .foregroundStyle(primary)
                            .padding(16)
                            .background(primary.opacity(0.18), in: Circle())
                        Text(AppL10n.string("weight.records.empty.title"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text(AppL10n.string("weight.records.empty.body"))
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 260)
                        Button(AppL10n.string("weight.records.first_button")) {
                            showAddSheet = true
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                        .background(primary, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(24)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(sortedEntries) { entry in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(AppL10n.format("weight.value.format", entry.weightKg))
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text(dateTimeText(entry.recordedAt))
                                            .font(.system(size: 12))
                                            .foregroundStyle(.gray)
                                        Text(entry.source.label)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(sourceColor(for: entry.source))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(sourceColor(for: entry.source).opacity(0.15), in: Capsule())
                                    }

                                    Spacer()

                                    Menu {
                                        Button(AppL10n.string("Edit")) {
                                            editingEntry = entry
                                        }
                                        Button(AppL10n.string("Delete"), role: .destructive) {
                                            deletingEntry = entry
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(.gray)
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                .padding(16)
                                .background(cardDark, in: RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle(AppL10n.string("weight.records.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(AppL10n.string("Close")) {
                        dismiss()
                    }
                    .foregroundStyle(.gray)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.string("Add Entry")) {
                        showAddSheet = true
                    }
                    .foregroundStyle(primary)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                WeightEntrySheetView(
                    onSave: { weightKg, recordedAt in
                        weightStore.addEntry(weightKg: weightKg, recordedAt: recordedAt)
                        showAddSheet = false
                    },
                    onCancel: {
                        showAddSheet = false
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: Binding(
                get: { editingEntry != nil },
                set: { if !$0 { editingEntry = nil } }
            )) {
                if let editingEntry {
                    WeightEntrySheetView(
                        initialWeightKg: editingEntry.weightKg,
                        initialDate: editingEntry.recordedAt,
                        onSave: { weightKg, recordedAt in
                            weightStore.updateEntry(
                                id: editingEntry.id,
                                weightKg: weightKg,
                                recordedAt: recordedAt,
                                source: editingEntry.source
                            )
                            self.editingEntry = nil
                        },
                        onCancel: {
                            self.editingEntry = nil
                        }
                    )
                    .presentationDetents([.large])
                }
            }
            .alert(
                AppL10n.string("weight.records.delete.title"),
                isPresented: Binding(
                    get: { deletingEntry != nil },
                    set: { if !$0 { deletingEntry = nil } }
                ),
                actions: {
                    Button(AppL10n.string("Delete"), role: .destructive) {
                        if let deletingEntry {
                            weightStore.deleteEntry(id: deletingEntry.id)
                        }
                        deletingEntry = nil
                    }
                    Button(AppL10n.string("Cancel"), role: .cancel) {
                        deletingEntry = nil
                    }
                },
                message: {
                    Text(AppL10n.string("weight.records.delete.message"))
                }
            )
        }
    }

    private var sortedEntries: [WeightEntry] {
        weightStore.entries.sorted { $0.recordedAt > $1.recordedAt }
    }

    private func dateTimeText(_ date: Date) -> String {
        let formatter = AppL10n.formatter(dateFormat: "yyyy-MM-dd HH:mm")
        return formatter.string(from: date)
    }

    private func sourceColor(for source: WeightRecordSource) -> Color {
        switch source {
        case .manual:
            return primary
        case .healthKit:
            return .green
        }
    }
}

#Preview {
    WeightEntriesSheetView()
        .environmentObject(WeightStore())
        .preferredColorScheme(.dark)
}
