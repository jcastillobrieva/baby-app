import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Baby Header
                    if let baby = appState.currentBaby {
                        BabyHeaderCard(baby: baby)
                    }

                    // Today's Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hoy")
                            .font(.title2)
                            .fontWeight(.bold)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            StatCard(
                                title: "Sueño",
                                value: viewModel.todaySleepHours,
                                icon: "moon.fill",
                                color: .indigo
                            )

                            StatCard(
                                title: "Comidas",
                                value: "\(viewModel.todayFeedingCount)",
                                icon: "fork.knife",
                                color: .orange
                            )

                            StatCard(
                                title: "Pañales",
                                value: "\(viewModel.todayDiaperCount)",
                                icon: "drop.fill",
                                color: .cyan
                            )

                            StatCard(
                                title: "Último registro",
                                value: viewModel.lastLogTime,
                                icon: "clock.fill",
                                color: .gray
                            )
                        }
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Registro rápido")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            QuickActionButton(
                                title: "Sueño",
                                icon: "moon.fill",
                                color: .indigo
                            ) {
                                viewModel.showSleepLog = true
                            }

                            QuickActionButton(
                                title: "Comida",
                                icon: "fork.knife",
                                color: .orange
                            ) {
                                viewModel.showFeedingLog = true
                            }

                            QuickActionButton(
                                title: "Pañal",
                                icon: "drop.fill",
                                color: .cyan
                            ) {
                                viewModel.showDiaperLog = true
                            }
                        }
                    }

                    // Active Timer
                    if appState.activeSleepSession != nil {
                        ActiveTimerCard(
                            title: "Durmiendo",
                            startTime: appState.activeSleepSession!.startTime,
                            color: .indigo
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Inicio")
            .refreshable {
                await viewModel.loadTodayData(babyId: appState.currentBaby?.id)
            }
        }
    }
}

// MARK: - Baby Header Card

struct BabyHeaderCard: View {
    let baby: Baby

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "face.smiling")
                .font(.system(size: 48))
                .foregroundStyle(.pink)

            VStack(alignment: .leading, spacing: 4) {
                Text(baby.firstName)
                    .font(.title2)
                    .fontWeight(.bold)

                let age = AgeCalculator.calculate(from: baby.dateOfBirth)
                Text(age.displayString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Active Timer Card

struct ActiveTimerCard: View {
    let title: String
    let startTime: Date
    let color: Color

    @State private var elapsed = 0

    var body: some View {
        HStack {
            Image(systemName: "timer")
                .font(.title2)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(DateFormatters.formatTimer(seconds: elapsed))
                    .font(.title)
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { updateElapsed() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateElapsed()
        }
    }

    private func updateElapsed() {
        elapsed = Int(Date().timeIntervalSince(startTime))
    }
}
