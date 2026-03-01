import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
                .tag(0)

            TrackingView()
                .tabItem {
                    Label("Registro", systemImage: "chart.bar.fill")
                }
                .tag(1)

            AIChatView()
                .tabItem {
                    Label("IA", systemImage: "brain.head.profile")
                }
                .tag(2)

            DevelopmentView()
                .tabItem {
                    Label("Desarrollo", systemImage: "figure.child")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .modifier(NightModeModifier(isNightMode: appState.isNightMode))
    }
}
