import SwiftUI

struct BedtimeRoutineView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var bath = false
    @State private var pajamas = false
    @State private var diaperChange = false
    @State private var bottle = false
    @State private var story = false
    @State private var song = false
    @State private var whiteNoise = false
    @State private var notes = ""
    @State private var isLoading = false

    let sleepSessionId: UUID?

    private let supabase = SupabaseService.shared.client

    var body: some View {
        NavigationStack {
            List {
                Section("Rutina de hoy") {
                    RoutineToggle(title: "Baño", icon: "shower.fill", color: .blue, isOn: $bath)
                    RoutineToggle(title: "Pijama", icon: "tshirt.fill", color: .purple, isOn: $pajamas)
                    RoutineToggle(title: "Cambio de pañal", icon: "drop.fill", color: .cyan, isOn: $diaperChange)
                    RoutineToggle(title: "Biberón", icon: "waterbottle.fill", color: .orange, isOn: $bottle)
                    RoutineToggle(title: "Cuento", icon: "book.fill", color: .green, isOn: $story)
                    RoutineToggle(title: "Canción de cuna", icon: "music.note", color: .pink, isOn: $song)
                    RoutineToggle(title: "Ruido blanco", icon: "waveform", color: .gray, isOn: $whiteNoise)
                }

                Section("Notas") {
                    TextField("Notas adicionales...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Rutina de dormir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await save() }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }

    private func save() async {
        guard let baby = appState.currentBaby else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await supabase.auth.session.user.id

            var params: [String: String] = [
                "baby_id": baby.id.uuidString,
                "date": DateFormatters.dateOnly.string(from: Date()),
                "bath": String(bath),
                "pajamas": String(pajamas),
                "diaper_change": String(diaperChange),
                "bottle": String(bottle),
                "story": String(story),
                "song": String(song),
                "white_noise": String(whiteNoise),
                "logged_by": userId.uuidString
            ]

            if let sessionId = sleepSessionId {
                params["sleep_session_id"] = sessionId.uuidString
            }

            if !notes.isEmpty {
                params["notes"] = notes
            }

            try await supabase
                .from("bedtime_routines")
                .insert(params)
                .execute()

            dismiss()
        } catch {
            // Handle error
        }
    }
}

// MARK: - Routine Toggle Row

struct RoutineToggle: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
            }
        }
    }
}
