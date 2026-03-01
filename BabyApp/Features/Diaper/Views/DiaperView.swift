import SwiftUI

struct DiaperView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DiaperViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Log Buttons
                VStack(spacing: 16) {
                    Text("Registrar pañal")
                        .font(.title3)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        DiaperQuickButton(
                            title: "Mojado",
                            icon: "drop.fill",
                            color: .cyan
                        ) {
                            Task { await viewModel.logDiaper(type: .wet) }
                        }

                        DiaperQuickButton(
                            title: "Sucio",
                            icon: "leaf.fill",
                            color: .brown
                        ) {
                            Task { await viewModel.logDiaper(type: .dirty) }
                        }

                        DiaperQuickButton(
                            title: "Ambos",
                            icon: "drop.fill",
                            color: .purple
                        ) {
                            Task { await viewModel.logDiaper(type: .both) }
                        }
                    }

                    // Optional details toggle
                    DisclosureGroup("Detalles opcionales") {
                        VStack(spacing: 12) {
                            Picker("Consistencia", selection: $viewModel.consistency) {
                                Text("--").tag(nil as DiaperLog.Consistency?)
                                Text("Líquida").tag(DiaperLog.Consistency.liquid as DiaperLog.Consistency?)
                                Text("Blanda").tag(DiaperLog.Consistency.soft as DiaperLog.Consistency?)
                                Text("Formada").tag(DiaperLog.Consistency.formed as DiaperLog.Consistency?)
                                Text("Dura").tag(DiaperLog.Consistency.hard as DiaperLog.Consistency?)
                            }

                            Picker("Color", selection: $viewModel.color) {
                                Text("--").tag(nil as DiaperLog.DiaperColor?)
                                Text("Amarillo").tag(DiaperLog.DiaperColor.yellow as DiaperLog.DiaperColor?)
                                Text("Verde").tag(DiaperLog.DiaperColor.green as DiaperLog.DiaperColor?)
                                Text("Café").tag(DiaperLog.DiaperColor.brown as DiaperLog.DiaperColor?)
                                Text("Negro").tag(DiaperLog.DiaperColor.black as DiaperLog.DiaperColor?)
                            }

                            Toggle("Tiene sangre", isOn: $viewModel.hasBlood)
                            Toggle("Tiene mucosidad", isOn: $viewModel.hasMucus)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8)

                // Today's Count
                HStack(spacing: 20) {
                    DiaperCountBadge(count: viewModel.wetCount, label: "Mojados", color: .cyan)
                    DiaperCountBadge(count: viewModel.dirtyCount, label: "Sucios", color: .brown)
                    DiaperCountBadge(count: viewModel.bothCount, label: "Ambos", color: .purple)
                }

                // History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Historial de hoy")
                        .font(.title3)
                        .fontWeight(.bold)

                    if viewModel.todayLogs.isEmpty {
                        Text("Sin registros de pañales hoy")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(viewModel.todayLogs) { log in
                            DiaperLogRow(log: log)
                        }
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.loadLogs(babyId: appState.currentBaby?.id)
        }
    }
}

// MARK: - Quick Button

struct DiaperQuickButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Count Badge

struct DiaperCountBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Log Row

struct DiaperLogRow: View {
    let log: DiaperLog

    var body: some View {
        HStack {
            Circle()
                .fill(colorForType(log.type))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading) {
                Text(titleForType(log.type))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(DateFormatters.time.string(from: log.changedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if log.hasBlood {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func titleForType(_ type: DiaperLog.DiaperType) -> String {
        switch type {
        case .wet: return "Mojado"
        case .dirty: return "Sucio"
        case .both: return "Mojado y sucio"
        }
    }

    private func colorForType(_ type: DiaperLog.DiaperType) -> Color {
        switch type {
        case .wet: return .cyan
        case .dirty: return .brown
        case .both: return .purple
        }
    }
}
