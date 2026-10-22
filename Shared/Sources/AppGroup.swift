import Foundation
import PolyCore

/// The app group that the app and the widgets share.
enum AppGroup {
    static let identifier = "group.io.github.stivengjekaj.polytechnium"

    /// The settings that the app and the widgets share, or the settings of the
    /// app alone when the group is not available.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    static var store: DataStore {
        DataStore.shared(group: identifier)
    }
}
