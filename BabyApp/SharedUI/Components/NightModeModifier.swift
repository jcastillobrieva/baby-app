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
struct NightModeOverlay: View {
    @Environment(AppState.self) private var appState
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                // Clock
                Text(DateFormatters.time.string(from: Date()))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundStyle(.red.opacity(0.8))

                Spacer()

                // Big buttons
                NightModeButton(
                    title: "Sueño",
                    icon: "moon.fill",
                    color: .red
                ) {
                    // TODO: Quick sleep log
                }

                NightModeButton(
                    title: "Biberón",
                    icon: "waterbottle.fill",
                    color: .red
                ) {
                    // TODO: Quick bottle log
                }

                NightModeButton(
                    title: "Pañal",
                    icon: "drop.fill",
                    color: .red
                ) {
                    // TODO: Quick diaper log
                }

                Spacer()

                Button("Salir modo nocturno") {
                    onDismiss()
                }
                .foregroundStyle(.red.opacity(0.5))
            }
            .padding(32)
        }
    }
}
