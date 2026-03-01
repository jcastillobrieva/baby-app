import SwiftUI

struct PlanningView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = PlanningViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Picker
                    DatePicker(
                        "Fecha",
                        selection: $viewModel.selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)

                    // Plan Items
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Plan del día")
                                .font(.title3)
                                .fontWeight(.bold)

                            Spacer()

                            Button {
                                viewModel.showAddItem = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                        }

                        if viewModel.planItems.isEmpty {
                            Text("Sin actividades planificadas")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(viewModel.planItems) { item in
                                PlanItemRow(item: item) {
                                    Task { await viewModel.toggleItem(item) }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Planificación")
            .task {
                await viewModel.loadPlan(babyId: appState.currentBaby?.id)
            }
        }
    }
}

// MARK: - Plan Item Row

struct PlanItemRow: View {
    let item: PlanItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.completed ? .green : .gray)
            }

            if let time = item.scheduledTime {
                Text(time)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
            }

            Image(systemName: iconForType(item.type))
                .foregroundStyle(colorForType(item.type))

            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.subheadline)
                    .strikethrough(item.completed)

                if let desc = item.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "sleep": return "moon.fill"
        case "feed": return "fork.knife"
        case "diaper": return "drop.fill"
        case "play": return "gamecontroller.fill"
        case "bath": return "shower.fill"
        case "medicine": return "cross.case.fill"
        default: return "star.fill"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "sleep": return .indigo
        case "feed": return .orange
        case "diaper": return .cyan
        case "play": return .green
        case "bath": return .blue
        case "medicine": return .red
        default: return .gray
        }
    }
}

// MARK: - Plan Item Model (for display)

struct PlanItem: Codable, Identifiable {
    let id: UUID
    let dailyPlanId: UUID
    let scheduledTime: String?
    let type: String
    let title: String
    let description: String?
    var completed: Bool
    let completedAt: Date?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case dailyPlanId = "daily_plan_id"
        case scheduledTime = "scheduled_time"
        case type, title, description, completed
        case completedAt = "completed_at"
        case sortOrder = "sort_order"
    }
}
