import SwiftUI

/// The tabs of the app.
struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label(tr("Today"), systemImage: "clock") }
            TimetableScreen()
                .tabItem { Label(tr("Timetable"), systemImage: "calendar") }
            GradesScreen()
                .tabItem { Label(tr("Grades"), systemImage: "graduationcap") }
            ExamsScreen()
                .tabItem { Label(tr("Exams"), systemImage: "hourglass") }
        }
        .polyScreen()
        .alert(tr("Fault"), isPresented: Binding(get: { app.fault != nil }, set: { if !$0 { app.fault = nil } })) {
            Button(tr("OK")) { app.fault = nil }
        } message: {
            Text(app.fault ?? "")
        }
    }
}
