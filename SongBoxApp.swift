import SwiftUI

@main
struct SurvivalApp: App {
    @StateObject private var nav = Nav()
    @AppStorage("theme") private var theme = "system"
    private var scheme: ColorScheme? { theme == "light" ? .light : theme == "dark" ? .dark : nil }

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Знания", systemImage: "book.closed.fill") { GuidesView() }
                Tab("Карта", systemImage: "location.north.line.fill") { NavView() }
                Tab("Инструменты", systemImage: "wrench.and.screwdriver.fill") { ToolsView() }
            }
            .environmentObject(nav)
            .preferredColorScheme(scheme)
            .tint(.primary)
        }
    }
}
