import SwiftUI
import SwiftData

@main
struct FastFlowApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var timerViewModel: FastFlowTimerViewModel
    @StateObject private var syncedPreferencesStore: SyncedPreferencesStore
    @StateObject private var weightStore: WeightStore
    @StateObject private var sessionFeedbackStore: FastingSessionFeedbackStore
    @StateObject private var cloudSyncRuntime: CloudSyncRuntime
    @StateObject private var monetizationRuntime = MonetizationRuntime()
    @StateObject private var subscriptionRuntime = SubscriptionRuntime()
    @StateObject private var languageStore: AppLanguageStore
    @AppStorage(FastFlowDefaultsKey.onboardingCompleted) private var onboardingCompleted = false
    @AppStorage(FastFlowDefaultsKey.adInventoryMode) private var adInventoryModeRaw = AdInventoryMode.buildFallbackDefault.rawValue
    private let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema(versionedSchema: FastFlowSchemaV4.self)
        let containerSetup = Self.makeSharedContainer(schema: schema)
        sharedModelContainer = containerSetup.container
        _cloudSyncRuntime = StateObject(
            wrappedValue: CloudSyncRuntime(
                mode: containerSetup.mode,
                lastErrorDescription: containerSetup.errorDescription
            )
        )
        let container = containerSetup.container
        let syncedPreferencesStore = SyncedPreferencesStore(modelContext: container.mainContext)
        _syncedPreferencesStore = StateObject(
            wrappedValue: syncedPreferencesStore
        )
        let languageStore = AppLanguageStore(syncedPreferencesStore: syncedPreferencesStore)
        _languageStore = StateObject(
            wrappedValue: languageStore
        )
        let timerViewModel = FastFlowTimerViewModel()
        timerViewModel.configure(syncedPreferencesStore: syncedPreferencesStore)
        _timerViewModel = StateObject(
            wrappedValue: timerViewModel
        )
        _weightStore = StateObject(
            wrappedValue: WeightStore(modelContext: container.mainContext)
        )
        _sessionFeedbackStore = StateObject(
            wrappedValue: FastingSessionFeedbackStore(modelContext: container.mainContext)
        )
        configureMonetizationDefaults()
    }

    var body: some Scene {
        WindowGroup {
            FastFlowTimerView()
                .environmentObject(timerViewModel)
                .environmentObject(syncedPreferencesStore)
                .environmentObject(weightStore)
                .environmentObject(sessionFeedbackStore)
                .environmentObject(cloudSyncRuntime)
                .environmentObject(monetizationRuntime)
                .environmentObject(subscriptionRuntime)
                .environmentObject(languageStore)
                .environment(\.locale, languageStore.locale)
                .fullScreenCover(
                    isPresented: Binding(
                        get: { !onboardingCompleted },
                        set: { _ in }
                    )
                ) {
                    OnboardingView()
                        .environmentObject(timerViewModel)
                        .environmentObject(syncedPreferencesStore)
                        .environmentObject(languageStore)
                        .environment(\.locale, languageStore.locale)
                }
                .task {
                    let mode = MonetizationPolicy.adMode(from: adInventoryModeRaw)
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            await monetizationRuntime.prepareForLaunch(adMode: mode)
                        }
                        group.addTask {
                            await subscriptionRuntime.prepareForLaunch()
                        }
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    syncedPreferencesStore.refreshFromStore()
                    timerViewModel.refreshFromSyncedPreferences()
                    weightStore.refreshFromStore()
                    sessionFeedbackStore.refreshFromStore()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func configureMonetizationDefaults() {
        let defaults = UserDefaults.standard
        #if DEBUG
        if defaults.string(forKey: FastFlowDefaultsKey.adInventoryMode) == nil {
            defaults.set(MonetizationPolicy.defaultAdMode().rawValue, forKey: FastFlowDefaultsKey.adInventoryMode)
        }
        #else
        defaults.set(MonetizationPolicy.defaultAdMode().rawValue, forKey: FastFlowDefaultsKey.adInventoryMode)
        #endif
    }

    private static func makeSharedContainer(schema: Schema) -> (
        container: ModelContainer,
        mode: CloudSyncMode,
        errorDescription: String?
    ) {
        let localConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let cloudConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: FastFlowMigrationPlan.self,
                configurations: cloudConfiguration
            )
            return (container, .cloudKit, nil)
        } catch {
            let cloudError = error
            do {
                let container = try ModelContainer(
                    for: schema,
                    migrationPlan: FastFlowMigrationPlan.self,
                    configurations: localConfiguration
                )
                return (container, .localOnly, cloudError.localizedDescription)
            } catch {
                let localError = error
                do {
                    let container = try ModelContainer(
                        for: schema,
                        migrationPlan: FastFlowMigrationPlan.self,
                        configurations: inMemoryConfiguration
                    )
                    let combinedError = [cloudError.localizedDescription, localError.localizedDescription]
                        .joined(separator: " | ")
                    return (container, .localOnly, combinedError)
                } catch {
                    let inMemoryError = error
                    let combinedError = [
                        cloudError.localizedDescription,
                        localError.localizedDescription,
                        inMemoryError.localizedDescription
                    ].joined(separator: " | ")

                    do {
                        let emergencyContainer = try ModelContainer(
                            for: schema,
                            configurations: inMemoryConfiguration
                        )
                        return (emergencyContainer, .localOnly, combinedError)
                    } catch {
                        fatalError("Failed to initialize any ModelContainer: \(error)")
                    }
                }
            }
        }
    }
}
