import SwiftUI

/// The tabs of the app.
struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        TabView {
            SettingsScreen()
                .tabItem { Label(tr("Settings"), systemImage: "gearshape") }
        }
        .polyScreen()
        .alert(tr("Fault"), isPresented: Binding(get: { app.fault != nil }, set: { if !$0 { app.fault = nil } })) {
            Button(tr("OK")) { app.fault = nil }
        } message: {
            Text(app.fault ?? "")
        }
    }
}
