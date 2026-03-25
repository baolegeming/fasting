import SwiftUI

struct EndFastFeedbackSheetView: View {
    let resultStatus: FastingSessionResultStatus
    let onComplete: (FastingSubjectiveFeeling, FastingCompletedObjectiveState) -> Void
    let onEndEarly: (FastingSubjectiveFeeling, FastingNotCompletedReason) -> Void
    let onCancel: () -> Void

    @State private var subjectiveFeeling: FastingSubjectiveFeeling?
    @State private var completedObjectiveState: FastingCompletedObjectiveState?
    @State private var notCompletedReason: FastingNotCompletedReason?

    private let primary = Color(hex: "ec5b13")
    private let cardDark = Color(hex: "1C1C1E")
    private let backgroundDark = Color(hex: "0F0F0F")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        feedbackSection(
                            title: AppL10n.string("session.feedback.subjective.title"),
                            subtitle: AppL10n.string("session.feedback.subjective.subtitle")
                        ) {
                            optionGrid(
                                items: FastingSubjectiveFeeling.allCases,
                                selection: $subjectiveFeeling
                            )
                        }

                        if resultStatus == .completed {
                            feedbackSection(
                                title: AppL10n.string("session.feedback.completed.title"),
                                subtitle: AppL10n.string("session.feedback.completed.subtitle")
                            ) {
                                optionGrid(
                                    items: FastingCompletedObjectiveState.allCases,
                                    selection: $completedObjectiveState
                                )
                            }
                        } else {
                            feedbackSection(
                                title: AppL10n.string("session.feedback.not_completed.title"),
                                subtitle: AppL10n.string("session.feedback.not_completed.subtitle")
                            ) {
                                optionGrid(
                                    items: FastingNotCompletedReason.allCases,
                                    selection: $notCompletedReason
                                )
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 120)
                }
            }
            .safeAreaInset(edge: .bottom) {
                footer
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppL10n.string("Cancel")) {
                        onCancel()
                    }
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resultStatus == .completed
                 ? AppL10n.string("session.feedback.completed.header")
                 : AppL10n.string("session.feedback.not_completed.header"))
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text(resultStatus == .completed
                 ? AppL10n.string("session.feedback.completed.body")
                 : AppL10n.string("session.feedback.not_completed.body"))
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .lineSpacing(3)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Divider()
                .overlay(Color.white.opacity(0.08))

            Button {
                submit()
            } label: {
                Text(resultStatus == .completed
                     ? AppL10n.string("session.feedback.completed.cta")
                     : AppL10n.string("session.feedback.not_completed.cta"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(canSubmit ? primary : Color.white.opacity(0.12))
                    )
            }
            .disabled(!canSubmit)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(backgroundDark)
    }

    private var canSubmit: Bool {
        guard subjectiveFeeling != nil else { return false }
        switch resultStatus {
        case .completed:
            return completedObjectiveState != nil
        case .notCompleted:
            return notCompletedReason != nil
        }
    }

    private func submit() {
        guard let subjectiveFeeling else { return }

        switch resultStatus {
        case .completed:
            guard let completedObjectiveState else { return }
            onComplete(subjectiveFeeling, completedObjectiveState)
        case .notCompleted:
            guard let notCompletedReason else { return }
            onEndEarly(subjectiveFeeling, notCompletedReason)
        }
    }

    private func feedbackSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .lineSpacing(3)
            content()
        }
        .padding(16)
        .background(cardDark, in: RoundedRectangle(cornerRadius: 18))
    }

    private func optionGrid<Option: Identifiable & CaseIterable & Hashable>(
        items: Option.AllCases,
        selection: Binding<Option?>
    ) -> some View where Option.AllCases: RandomAccessCollection, Option: FeedbackOptionTitleProviding {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(items), id: \.id) { item in
                let isSelected = selection.wrappedValue == item
                Button {
                    selection.wrappedValue = item
                } label: {
                    Text(item.optionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? .black : .white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? primary : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? primary : Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private protocol FeedbackOptionTitleProviding {
    var optionTitle: String { get }
}

extension FastingSubjectiveFeeling: FeedbackOptionTitleProviding {
    var optionTitle: String { title }
}

extension FastingCompletedObjectiveState: FeedbackOptionTitleProviding {
    var optionTitle: String { title }
}

extension FastingNotCompletedReason: FeedbackOptionTitleProviding {
    var optionTitle: String { title }
}

#Preview {
    EndFastFeedbackSheetView(
        resultStatus: .completed,
        onComplete: { _, _ in },
        onEndEarly: { _, _ in },
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
