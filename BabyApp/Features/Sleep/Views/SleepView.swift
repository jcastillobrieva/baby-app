import SwiftUI

struct SleepView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SleepViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Active Sleep Timer
                if viewModel.isTracking {
                    ActiveSleepCard(viewModel: viewModel)
                } else {
                    StartSleepCard(viewModel: viewModel)
                }

                // Today's Sleep
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sueño de hoy")
                        .font(.title3)
                        .fontWeight(.bold)

                    if viewModel.todaySessions.isEmpty {
                        Text("Sin registros de sueño hoy")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(viewModel.todaySessions) { session in
                            SleepSessionRow(session: session)
                        }
                    }
                }

                // Weekly Chart Placeholder
                VStack(alignment: .leading, spacing: 12) {
                    Text("Esta semana")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Gráfica de horas de sueño próximamente")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .task {
            await viewModel.loadSessions(babyId: appState.currentBaby?.id)
        }
    }
}

// MARK: - Start Sleep Card

struct StartSleepCard: View {
    @Bindable var viewModel: SleepViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(.indigo)

            Picker("Tipo", selection: $viewModel.sleepType) {
                Text("Noche").tag(SleepSession.SleepType.night)
                Text("Siesta").tag(SleepSession.SleepType.nap)
            }
            .pickerStyle(.segmented)

            TimerButton(
                title: "Iniciar sueño",
                color: .indigo
            ) {
                Task { await viewModel.startSleep() }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - Active Sleep Card

struct ActiveSleepCard: View {
    @Bindable var viewModel: SleepViewModel
    @State private var elapsed = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Durmiendo...")
                .font(.headline)
                .foregroundStyle(.indigo)

            Text(DateFormatters.formatTimer(seconds: elapsed))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(.indigo)

            HStack(spacing: 16) {
                Button("Despertar") {
                    viewModel.showAddWaking = true
                }
                .buttonStyle(.bordered)

                TimerButton(
                    title: "Desperté",
                    color: .indigo
                ) {
                    Task { await viewModel.stopSleep() }
                }
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { updateElapsed() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateElapsed()
        }
    }

    private func updateElapsed() {
        if let start = viewModel.currentSessionStart {
            elapsed = Int(Date().timeIntervalSince(start))
        }
    }
}

// MARK: - Session Row

struct SleepSessionRow: View {
    let session: SleepSession

    var body: some View {
        HStack {
            Image(systemName: session.type == .night ? "moon.fill" : "sun.max.fill")
                .foregroundStyle(session.type == .night ? .indigo : .orange)

            VStack(alignment: .leading) {
                Text(session.type == .night ? "Noche" : "Siesta")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(DateFormatters.time.string(from: session.startTime)) - \(session.endTime.map { DateFormatters.time.string(from: $0) } ?? "...")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let minutes = session.durationMinutes {
                Text(DateFormatters.formatDuration(minutes: minutes))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
