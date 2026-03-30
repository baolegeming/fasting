import Foundation

enum CloudSyncMode {
    case cloudKit
    case localOnly
}

@MainActor
final class CloudSyncRuntime: ObservableObject {
    @Published private(set) var mode: CloudSyncMode
    @Published private(set) var lastErrorDescription: String?

    init(mode: CloudSyncMode = .localOnly, lastErrorDescription: String? = nil) {
        self.mode = mode
        self.lastErrorDescription = lastErrorDescription
    }

    var isCloudSyncEnabled: Bool {
        mode == .cloudKit
    }

    func update(mode: CloudSyncMode, errorDescription: String? = nil) {
        self.mode = mode
        self.lastErrorDescription = errorDescription
    }
}
