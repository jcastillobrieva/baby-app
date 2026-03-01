import SwiftUI

struct FeedingView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = FeedingViewModel()
    @State private var selectedType: FeedingLog.FeedingType = .bottle

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Type Selector
                Picker("Tipo", selection: $selectedType) {
                    Text("Biberón").tag(FeedingLog.FeedingType.bottle)
                    Text("Pecho").tag(FeedingLog.FeedingType.breast)
                    Text("Sólidos").tag(FeedingLog.FeedingType.solid)
                }
                .pickerStyle(.segmented)

                // Input Card
                switch selectedType {
                case .bottle:
                    BottleInputCard(viewModel: viewModel)
                case .breast:
                    BreastInputCard(viewModel: viewModel)
                case .solid:
                    SolidFoodInputCard(viewModel: viewModel)
                }

                // Today's Log
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hoy")
                        .font(.title3)
                        .fontWeight(.bold)

                    if viewModel.todayLogs.isEmpty {
                        Text("Sin registros de alimentación hoy")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(viewModel.todayLogs) { log in
                            FeedingLogRow(log: log)
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

// MARK: - Bottle Input

struct BottleInputCard: View {
    @Bindable var viewModel: FeedingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waterbottle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Stepper(
                "Cantidad: \(String(format: "%.1f", viewModel.bottleOz)) oz",
                value: $viewModel.bottleOz,
                in: 0.5...12,
                step: 0.5
            )

            Button {
                Task { await viewModel.logBottle() }
            } label: {
                Text("Registrar biberón")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - Breast Input

struct BreastInputCard: View {
    @Bindable var viewModel: FeedingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(.pink)

            if viewModel.isBreastfeeding {
                // Timer active
                Text(DateFormatters.formatTimer(seconds: viewModel.breastfeedingElapsed))
                    .font(.system(size: 36, weight: .light, design: .monospaced))

                Text("Lado: \(viewModel.breastSide == .left ? "Izquierdo" : "Derecho")")
                    .font(.subheadline)

                Button {
                    Task { await viewModel.stopBreastfeeding() }
                } label: {
                    Text("Terminar")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // Side picker
                Picker("Lado", selection: $viewModel.breastSide) {
                    Text("Izquierdo").tag(FeedingLog.BreastSide.left)
                    Text("Derecho").tag(FeedingLog.BreastSide.right)
                    Text("Ambos").tag(FeedingLog.BreastSide.both)
                }
                .pickerStyle(.segmented)

                Button {
                    Task { await viewModel.startBreastfeeding() }
                } label: {
                    Text("Iniciar lactancia")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(viewModel.isBreastfeeding ? Color.pink.opacity(0.1) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - Solid Food Input

struct SolidFoodInputCard: View {
    @Bindable var viewModel: FeedingViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "carrot.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            TextField("Alimento", text: $viewModel.solidFoodName)
                .textFieldStyle(.roundedBorder)

            Picker("Preparación", selection: $viewModel.solidPreparation) {
                Text("Puré").tag(SolidFoodLog.Preparation.puree)
                Text("Machacado").tag(SolidFoodLog.Preparation.mashed)
                Text("Picado").tag(SolidFoodLog.Preparation.chopped)
                Text("BLW").tag(SolidFoodLog.Preparation.blw)
            }
            .pickerStyle(.segmented)

            Picker("Cantidad", selection: $viewModel.solidAmount) {
                Text("Prueba").tag(SolidFoodLog.Amount.taste)
                Text("Poca").tag(SolidFoodLog.Amount.small)
                Text("Media").tag(SolidFoodLog.Amount.medium)
                Text("Mucha").tag(SolidFoodLog.Amount.large)
            }
            .pickerStyle(.segmented)

            Picker("Reacción", selection: $viewModel.solidReaction) {
                Text("Ninguna").tag(SolidFoodLog.Reaction.none)
                Text("Le gustó").tag(SolidFoodLog.Reaction.liked)
                Text("No le gustó").tag(SolidFoodLog.Reaction.disliked)
                Text("Alergia").tag(SolidFoodLog.Reaction.allergic)
            }

            Button {
                Task { await viewModel.logSolidFood() }
            } label: {
                Text("Registrar alimento")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.solidFoodName.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - Feeding Log Row

struct FeedingLogRow: View {
    let log: FeedingLog

    var body: some View {
        HStack {
            Image(systemName: iconForType(log.type))
                .foregroundStyle(colorForType(log.type))

            VStack(alignment: .leading) {
                Text(titleForType(log))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(DateFormatters.time.string(from: log.startTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(detailForType(log))
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func iconForType(_ type: FeedingLog.FeedingType) -> String {
        switch type {
        case .bottle: return "waterbottle.fill"
        case .breast: return "heart.fill"
        case .solid: return "carrot.fill"
        }
    }

    private func colorForType(_ type: FeedingLog.FeedingType) -> Color {
        switch type {
        case .bottle: return .orange
        case .breast: return .pink
        case .solid: return .green
        }
    }

    private func titleForType(_ log: FeedingLog) -> String {
        switch log.type {
        case .bottle: return "Biberón"
        case .breast:
            let side = log.breastSide == .left ? "Izq" : log.breastSide == .right ? "Der" : "Ambos"
            return "Pecho (\(side))"
        case .solid: return "Sólidos"
        }
    }

    private func detailForType(_ log: FeedingLog) -> String {
        switch log.type {
        case .bottle:
            return "\(String(format: "%.1f", log.amountOz ?? 0)) oz"
        case .breast:
            return "\(log.durationMinutes ?? 0) min"
        case .solid:
            return ""
        }
    }
}
