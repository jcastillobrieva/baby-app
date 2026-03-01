import SwiftUI

/// View modifier that applies Night Mode styling.
/// Night Mode: dark red tint, large buttons, minimal UI.
/// Auto-activates between 8PM and 7AM.
struct NightModeModifier: ViewModifier {
    let isNightMode: Bool

    func body(content: Content) -> some View {
        if isNightMode {
            content
                .preferredColorScheme(.dark)
                .tint(.red)
                .overlay(
                    Color.red.opacity(0.05)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                )
        } else {
            content
        }
    }
}

/// Night Mode overlay view with minimal, large-button UI for 1AM logging.
/// Buttons are 60pt+ for easy tapping in the dark.
struct NightModeOverlay: View {
    @Environment(AppState.self) private var appState
    let onDismiss: () -> Void

    @State private var sleepViewModel = SleepViewModel()
    @State private var feedingViewModel = FeedingViewModel()
    @State private var diaperViewModel = DiaperViewModel()

    @State private var showConfirmation: String?
    @State private var bottleOz: Double = 4.0
    @State private var currentTime = Date()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Clock — updates every second
                Text(DateFormatters.time.string(from: currentTime))
                    .font(.system(size: 56, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(.red.opacity(0.8))
                    .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { time in
                        currentTime = time
                    }

                // Baby name
                if let baby = appState.currentBaby {
                    Text(baby.firstName)
                        .font(.title3)
                        .foregroundStyle(.red.opacity(0.5))
                }

                Spacer()

                // Confirmation toast
                if let msg = showConfirmation {
                    Text(msg)
                        .font(.headline)
                        .foregroundStyle(.green)
                        .padding()
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.opacity)
                }

                // Sleep button
                if sleepViewModel.isTracking {
                    NightModeButton(
                        title: "Desperté",
                        icon: "sun.max.fill",
                        color: .red
                    ) {
                        Task {
                            await sleepViewModel.stopSleep()
                            showToast("Sueño registrado")
                        }
                    }
                } else {
                    NightModeButton(
                        title: "Dormir",
                        icon: "moon.fill",
                        color: .red
                    ) {
                        Task {
                            await sleepViewModel.startSleep()
                            showToast("Sueño iniciado")
                        }
                    }
                }

                // Bottle button
                NightModeButton(
                    title: "Biberón \(String(format: "%.0f", bottleOz))oz",
                    icon: "waterbottle.fill",
                    color: .red
                ) {
                    Task {
                        feedingViewModel.bottleOz = bottleOz
                        await feedingViewModel.logBottle()
                        showToast("Biberón registrado")
                    }
                }

                // Diaper button
                NightModeButton(
                    title: "Pañal",
                    icon: "drop.fill",
                    color: .red
                ) {
                    Task {
                        await diaperViewModel.logDiaper(type: .wet)
                        showToast("Pañal registrado")
                    }
                }

                Spacer()

                Button("Salir modo nocturno") {
                    onDismiss()
                }
                .foregroundStyle(.red.opacity(0.4))
                .font(.caption)
            }
            .padding(32)
        }
        .task {
            let babyId = appState.currentBaby?.id
            await sleepViewModel.loadSessions(babyId: babyId)
            await feedingViewModel.loadLogs(babyId: babyId)
            await diaperViewModel.loadLogs(babyId: babyId)
        }
    }

    private func showToast(_ message: String) {
        withAnimation {
            showConfirmation = message
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showConfirmation = nil
            }
        }
    }
}
