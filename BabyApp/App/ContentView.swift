import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else if !appState.isAuthenticated {
                LoginView()
            } else if appState.needsOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.needsOnboarding)
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.pink)

            Text("Baby App")
                .font(.largeTitle)
                .fontWeight(.bold)

            ProgressView()
                .padding(.top, 8)
        }
    }
}

// MARK: - Onboarding (Add first baby)

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var showInviteSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "face.smiling")
                    .font(.system(size: 80))
                    .foregroundStyle(.pink)

                Text("Bienvenido!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Agrega los datos de tu bebé o únete a la familia de otro padre")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink {
                        AddBabyView()
                    } label: {
                        Text("Agregar bebé")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.pink)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button("Tengo un código de invitación") {
                        showInviteSheet = true
                    }
                    .foregroundStyle(.pink)
                }
                .padding(.horizontal, 32)

                Button("Cerrar sesión") {
                    Task { await appState.signOut() }
                }
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            AcceptInviteView()
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var showNightOverlay = false

    var body: some View {
        ZStack {
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

            // Night mode fullscreen overlay
            if showNightOverlay {
                NightModeOverlay {
                    showNightOverlay = false
                    appState.isNightMode = false
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showNightOverlay)
        .onChange(of: appState.isNightMode) { _, isNight in
            if isNight { showNightOverlay = true }
        }
        .task {
            _ = await NotificationService.shared.requestPermission()
            // Show night overlay on initial launch if night mode
            if appState.isNightMode {
                showNightOverlay = true
            }
        }
    }
}
