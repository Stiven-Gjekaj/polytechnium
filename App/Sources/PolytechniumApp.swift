import SwiftUI
import UIKit

@main
struct PolytechniumApp: App {
    @State private var app = AppModel()

    init() {
        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = .black
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
        let title = [NSAttributedString.Key.font: Karla.uiFont(17, .bold)]
        UINavigationBar.appearance().titleTextAttributes = title
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                // A new language draws each screen again with its text.
                .id(app.language)
                .environment(\.locale, L10n.locale)
        }
    }
}
