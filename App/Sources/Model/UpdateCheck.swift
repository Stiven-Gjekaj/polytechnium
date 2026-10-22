import Foundation
import PolyCore

/// Asks GitHub for the newest release of the app.
enum UpdateCheck {
    static let latest = URL(string: "https://api.github.com/repos/Stiven-Gjekaj/polytechnium/releases/latest")!

    /// The newest version, when it is newer than this version. Nil with no network.
    static func newerVersion() async -> String? {
        var request = URLRequest(url: latest, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = object["tag_name"] as? String,
              AppVersion.isNewer(tag, than: AppInfo.version)
        else { return nil }
        return tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }
}
