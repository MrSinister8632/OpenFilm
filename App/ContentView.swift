import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PhotosTab()
                .tabItem {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                }

            RecipesTab()
                .tabItem {
                    Label("Recipes", systemImage: "slider.horizontal.3")
                }

            CreateTab()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }

            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
