import SwiftUI
import SwiftData

@main
struct OpenFilmApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Recipe.self, EditSession.self, UserPreferences.self])
    }
}
