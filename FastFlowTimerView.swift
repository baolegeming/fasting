import SwiftUI
import SwiftData

enum FastFlowTimerStatus {
    case notStarted
    case fasting
}

private enum FastFlowTab: Hashable {
    case timer
    case history
    case stats
    case settings
}

struct FastFlowTimerView: View {
    @EnvironmentObject private var viewModel: FastFlowTimerViewModel
    @EnvironmentObject private var feedbackStore: FastingSessionFeedbackStore
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: FastFlowTab = .timer
    @State private var showOngoingCorrectionSheet = false
    @State private var showCoachActionAlert = false
    @State private var coachActionAlertMessage = ""

    private let primary = Color(hex: "ec5b13")
    private let backgroundDark = Color(hex: "0F0F0F")

    var body: some View {
        TabView(selection: $selectedTab) {
            timerPage
                .tag(FastFlowTab.timer)
                .tabItem {
                    Label(AppL10n.string("Timer"), systemImage: "timer")
                }
            HistoryView()
                .tag(FastFlowTab.history)
                .tabItem {
                    Label(AppL10n.string("History"), systemImage: "calendar")
                }
            StatsView()
                .tag(FastFlowTab.stats)
                .tabItem {
                    Label(AppL10n.string("Stats"), systemImage: "chart.bar")
                }
            SettingsView()
                .tag(FastFlowTab.settings)
                .tabItem {
                    Label(AppL10n.string("Settings"), systemImage: "gearshape")
                }
        }
        .tint(primary)
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }

    private var timerPage: some View {
        NavigationStack {
            ZStack {
                backgroundDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        TimerRingView(
                            emoji: viewModel.timerEmoji,
                            title: viewModel.timerTitle,
                            progress: viewModel.ringProgress,
                            elapsedText: viewModel.elapsedText,
                            remainingText: viewModel.remainingText
                        )
                        .padding(.top, 24)

                        PhaseCardView(
                            phaseBadgeText: viewModel.phaseBadgeText,
                            activeStageCount: viewModel.activeStageCount,
                            phaseItems: viewModel.phaseItems
                        )

                        VStack(spacing: 12) {
                            ActionButtonsView(
                                status: viewModel.status,
                                hasReachedGoal: viewModel.hasReachedGoal,
                                onPrimaryAction: {
                                    if viewModel.status == .fasting {
                                        viewModel.requestEndCurrentFast()
                                    } else {
                                        viewModel.startFast()
                                    }
                                }
                            )

                            if viewModel.status == .fasting {
                                ongoingCorrectionCard
                            }

                            if let coachNote = viewModel.coachNote {
                                coachNoteCard(note: coachNote)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(AppL10n.string("FastFlow"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $viewModel.showEndFeedbackSheet) {
                if let pendingResult = viewModel.pendingSessionResult {
                    EndFastFeedbackSheetView(
                        resultStatus: pendingResult,
                        onComplete: { subjectiveFeeling, completedObjectiveState in
                            viewModel.completeFast(
                                subjectiveFeeling: subjectiveFeeling,
                                completedObjectiveState: completedObjectiveState,
                                feedbackStore: feedbackStore
                            )
                        },
                        onEndEarly: { subjectiveFeeling, notCompletedReason in
                            viewModel.endFastEarly(
                                subjectiveFeeling: subjectiveFeeling,
                                reason: notCompletedReason,
                                feedbackStore: feedbackStore
                            )
                        },
                        onCancel: {
                            viewModel.dismissEndFeedbackSheet()
                        }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                }
            }
            .sheet(isPresented: $viewModel.showPhaseModal) {
                PhaseModalSheetView(
                    phase: viewModel.phaseModalInfo,
                    onClose: {
                        viewModel.dismissPhaseModal()
                    }
                )
                .presentationDetents([.fraction(0.72), .large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showOngoingCorrectionSheet) {
                if let ongoingStartAt = viewModel.ongoingStartAt {
                    OngoingFastCorrectionSheetView(
                        initialStartAt: ongoingStartAt,
                        initialPlanType: viewModel.targetPlanType,
                        initialTargetDurationSec: viewModel.targetDurationSec,
                        onSave: { startAt, planType, durationSec in
                            viewModel.correctOngoingFast(
                                startAt: startAt,
                                planType: planType,
                                durationSec: durationSec
                            )
                            showOngoingCorrectionSheet = false
                        },
                        onDelete: {
                            viewModel.discardOngoingFast()
                            showOngoingCorrectionSheet = false
                        },
                        onCancel: {
                            showOngoingCorrectionSheet = false
                        }
                    )
                    .presentationDetents([.large])
                }
            }
            .alert(AppL10n.string("已更新"), isPresented: $showCoachActionAlert) {
                Button(AppL10n.string("确定"), role: .cancel) {}
            } message: {
                Text(coachActionAlertMessage)
            }
        }
    }

    private var ongoingCorrectionCard: some View {
        Button {
            showOngoingCorrectionSheet = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(primary)
                    .padding(10)
                    .background(primary.opacity(0.18), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppL10n.string("Need to adjust this session?"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text(AppL10n.string("如果是晚点开始或误触开始，可以在这里修正当前 session。"))
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.gray)
            }
            .padding(14)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func coachNoteCard(note: FastingCoachNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(note.body)
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                        .lineSpacing(3)
                }
                Spacer()
                Button {
                    viewModel.dismissCoachNote()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.gray)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.04), in: Circle())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(note.actionTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(primary)
                    .textCase(.uppercase)
                Text(note.actionDetail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineSpacing(3)
            }

            HStack(spacing: 8) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(primary)
                Text(note.educationEntry.title)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            if !note.actions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(note.actions) { action in
                        Button {
                            viewModel.applyCoachAction(action) { message in
                                coachActionAlertMessage = message
                                showCoachActionAlert = true
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(action.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(action.detail)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.72))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(primary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(primary.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    FastFlowTimerView()
        .environmentObject(FastFlowTimerViewModel())
        .environmentObject(WeightStore())
        .modelContainer(for: [FastingRecord.self, DailySummary.self], inMemory: true)
        .preferredColorScheme(.dark)
}
