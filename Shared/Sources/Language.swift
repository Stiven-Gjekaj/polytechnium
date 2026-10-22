import Foundation
import PolyCore

/// The language of the text of the app.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    /// The language of the device, when it is English or Albanian.
    case system
    case english = "en"
    case albanian = "sq"

    var id: String { rawValue }

    private static let key = "language"

    /// The language that the user chose.
    static var chosen: AppLanguage {
        get { AppLanguage(rawValue: AppGroup.defaults.string(forKey: key) ?? "") ?? .system }
        set { AppGroup.defaults.set(newValue.rawValue, forKey: key) }
    }

    /// The language of the text: the chosen one, or the first language of the
    /// device that the app has.
    static var effective: AppLanguage {
        if chosen != .system { return chosen }
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        return preferred.hasPrefix("sq") ? .albanian : .english
    }

    /// The name of a language, in that language, so that a user who cannot read
    /// the other one finds it.
    var name: String {
        switch self {
        case .system: tr("Language of the device")
        case .english: "English"
        case .albanian: "Shqip"
        }
    }
}

/// The text of a key in the chosen language. The key is the English text.
func tr(_ key: String) -> String {
    L10n.bundle.localizedString(forKey: key, value: key, table: nil)
}

/// The text of a key with values in the places of `%@` and `%d`.
func tr(_ key: String, _ values: CVarArg...) -> String {
    String(format: tr(key), locale: L10n.locale, arguments: values)
}

enum L10n {
    /// The folder of the strings of the effective language.
    static var bundle: Bundle {
        let code = AppLanguage.effective.rawValue
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    /// The locale for dates and numbers.
    static var locale: Locale {
        AppLanguage.effective == .albanian ? Locale(identifier: "sq_AL") : Locale(identifier: "en_GB")
    }

    /// A calendar with weeks that start on Monday, with the names of the language.
    static var calendar: Calendar {
        var calendar = Week.calendar
        calendar.locale = locale
        return calendar
    }
}
