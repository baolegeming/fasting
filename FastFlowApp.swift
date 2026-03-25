import SwiftUI
import SwiftData

@main
struct FastFlowApp: App {
    @StateObject private var timerViewModel = FastFlowTimerViewModel()
    @StateObject private var weightStore = WeightStore()
    @StateObject private var sessionFeedbackStore = FastingSessionFeedbackStore()
    @StateObject private var monetizationRuntime = MonetizationRuntime()
    @StateObject private var subscriptionRuntime = SubscriptionRuntime()
    @StateObject private var languageStore = AppLanguageStore.shared
    @AppStorage(FastFlowDefaultsKey.onboardingCompleted) private var onboardingCompleted = false
    @AppStorage(FastFlowDefaultsKey.adInventoryMode) private var adInventoryModeRaw = AdInventoryMode.buildFallbackDefault.rawValue
    private let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema(versionedSchema: FastFlowSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            sharedModelContainer = try ModelContainer(
                for: schema,
                migrationPlan: FastFlowMigrationPlan.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        configureMonetizationDefaults()
    }

    var body: some Scene {
        WindowGroup {
            FastFlowTimerView()
                .environmentObject(timerViewModel)
                .environmentObject(weightStore)
                .environmentObject(sessionFeedbackStore)
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
}
