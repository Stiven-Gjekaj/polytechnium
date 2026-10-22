import Foundation

extension AppData {
    public enum BackupFailure: Error, Equatable {
        /// The file is not a backup of the app.
        case notABackup
        /// A newer version of the app made the file. This version cannot read all of it.
        case tooNew(version: Int)
    }

    /// The data as a backup file.
    public func backup() throws -> Data {
        try DataStore.encoder.encode(self)
    }

    /// The data of a backup file. A file of a newer form gives an error, so that
    /// the restore does not lose the parts that this version does not know.
    public static func restore(_ data: Data) throws -> AppData {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let version = object["version"] as? Int
        else { throw BackupFailure.notABackup }
        guard version <= currentVersion else { throw BackupFailure.tooNew(version: version) }
        do {
            return try DataStore.decoder.decode(AppData.self, from: data)
        } catch {
            throw BackupFailure.notABackup
        }
    }
}

/// A version such as "1.0.0".
public enum AppVersion {
    /// True when `candidate` is newer than `current`. A "v" before the numbers is
    /// not a part of the version.
    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = parts(candidate), b = parts(current)
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0, y = index < b.count ? b[index] : 0
            if x != y { return x > y }
        }
        return false
    }

    static func parts(_ version: String) -> [Int] {
        let text = version.hasPrefix("v") ? String(version.dropFirst()) : version
        return text.split(separator: ".").map { Int($0.prefix { $0.isNumber }) ?? 0 }
    }
}
