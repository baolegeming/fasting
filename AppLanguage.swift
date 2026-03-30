import Foundation
import Combine
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case zh
    case en

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .zh:
            return "zh-Hans"
        case .en:
            return "en"
        }
    }

    var displayName: String {
        switch self {
        case .zh:
            return "中文"
        case .en:
            return "English"
        }
    }

    static func defaultValue(for locale: Locale = .current) -> AppLanguage {
        let region = locale.region?.identifier.uppercased() ?? ""
        return ["CN", "TW"].contains(region) ? .zh : .en
    }

    static func resolved(from defaults: UserDefaults = .standard, locale: Locale = .current) -> AppLanguage {
        if let rawValue = defaults.string(forKey: FastFlowDefaultsKey.appLanguage),
           let storedLanguage = AppLanguage(rawValue: rawValue) {
            return storedLanguage
        }
        return defaultValue(for: locale)
    }
}

@MainActor
final class AppLanguageStore: ObservableObject {
    @Published private(set) var language: AppLanguage

    private let defaults: UserDefaults
    private weak var syncedPreferencesStore: SyncedPreferencesStore?
    private var preferencesCancellable: AnyCancellable?

    init(
        defaults: UserDefaults = .standard,
        syncedPreferencesStore: SyncedPreferencesStore? = nil
    ) {
        self.defaults = defaults
        if let rawValue = defaults.string(forKey: FastFlowDefaultsKey.appLanguage),
           let storedLanguage = AppLanguage(rawValue: rawValue) {
            self.language = storedLanguage
        } else {
            let resolved = AppLanguage.defaultValue()
            defaults.set(resolved.rawValue, forKey: FastFlowDefaultsKey.appLanguage)
            self.language = resolved
        }
        if let syncedPreferencesStore {
            configure(syncedPreferencesStore: syncedPreferencesStore)
        }
    }

    var locale: Locale {
        Locale(identifier: language.localeIdentifier)
    }

    var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: language.localeIdentifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    func setLanguage(_ language: AppLanguage) {
        apply(language: language, persistToPreferences: true)
    }

    func configure(syncedPreferencesStore: SyncedPreferencesStore) {
        self.syncedPreferencesStore = syncedPreferencesStore
        apply(language: syncedPreferencesStore.appLanguage, persistToPreferences: false)
        preferencesCancellable = syncedPreferencesStore.$appLanguage
            .removeDuplicates()
            .sink { [weak self] language in
                self?.apply(language: language, persistToPreferences: false)
            }
    }

    private func apply(language: AppLanguage, persistToPreferences: Bool) {
        guard self.language != language else { return }
        self.language = language
        defaults.set(language.rawValue, forKey: FastFlowDefaultsKey.appLanguage)
        if persistToPreferences {
            syncedPreferencesStore?.setLanguage(language)
        }
    }
}

enum AppL10n {
    static var locale: Locale {
        Locale(identifier: currentLanguage.localeIdentifier)
    }

    static func string(_ key: String) -> String {
        currentBundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        let format = string(key)
        return withVaList(args) { pointer in
            NSString(format: format, locale: locale, arguments: pointer) as String
        }
    }

    static func formatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = dateFormat
        return formatter
    }

    private static var currentLanguage: AppLanguage {
        AppLanguage.resolved()
    }

    private static var currentBundle: Bundle {
        guard let path = Bundle.main.path(forResource: currentLanguage.localeIdentifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
