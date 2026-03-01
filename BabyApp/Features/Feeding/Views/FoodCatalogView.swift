import SwiftUI

struct FoodCatalogView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = FoodCatalogViewModel()
    @State private var selectedStatus: FoodCatalogItem.FoodStatus?
    @State private var showAddFood = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "Todos", isSelected: selectedStatus == nil) {
                            selectedStatus = nil
                        }
                        FilterChip(title: "Aprobados", isSelected: selectedStatus == .approved, color: .green) {
                            selectedStatus = .approved
                        }
                        FilterChip(title: "No probados", isSelected: selectedStatus == .untried, color: .gray) {
                            selectedStatus = .untried
                        }
                        FilterChip(title: "Vigilancia", isSelected: selectedStatus == .watch, color: .orange) {
                            selectedStatus = .watch
                        }
                        FilterChip(title: "Evitar", isSelected: selectedStatus == .avoid, color: .red) {
                            selectedStatus = .avoid
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                // Counts
                HStack(spacing: 16) {
                    CatalogCount(count: viewModel.approvedCount, label: "Aprobados", color: .green)
                    CatalogCount(count: viewModel.untriedCount, label: "Por probar", color: .gray)
                    CatalogCount(count: viewModel.watchCount, label: "Vigilancia", color: .orange)
                    CatalogCount(count: viewModel.avoidCount, label: "Evitar", color: .red)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Food List
                List {
                    ForEach(viewModel.filteredFoods(status: selectedStatus)) { food in
                        FoodCatalogRow(food: food) { newStatus in
                            Task { await viewModel.updateStatus(food: food, newStatus: newStatus) }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Catálogo de alimentos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddFood = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFood) {
                AddFoodView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadCatalog(babyId: appState.currentBaby?.id)
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .pink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Catalog Count

struct CatalogCount: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Food Catalog Row

struct FoodCatalogRow: View {
    let food: FoodCatalogItem
    let onStatusChange: (FoodCatalogItem.FoodStatus) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(food.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(food.category.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let pref = food.preference {
                        Text(preferenceEmoji(pref))
                            .font(.caption)
                    }

                    if food.allergyWatchUntil != nil {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Status menu
            Menu {
                Button("Aprobado") { onStatusChange(.approved) }
                Button("No probado") { onStatusChange(.untried) }
                Button("Vigilancia") { onStatusChange(.watch) }
                Button("Evitar") { onStatusChange(.avoid) }
            } label: {
                Text(statusLabel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
        }
    }

    private var statusColor: Color {
        switch food.status {
        case .approved: return .green
        case .untried: return .gray
        case .watch: return .orange
        case .avoid: return .red
        }
    }

    private var statusLabel: String {
        switch food.status {
        case .approved: return "Aprobado"
        case .untried: return "No probado"
        case .watch: return "Vigilancia"
        case .avoid: return "Evitar"
        }
    }

    private func preferenceEmoji(_ pref: FoodCatalogItem.FoodPreference) -> String {
        switch pref {
        case .loves: return "heart.fill"
        case .likes: return "hand.thumbsup.fill"
        case .neutral: return "minus.circle"
        case .dislikes: return "hand.thumbsdown.fill"
        }
    }
}

// MARK: - Add Food Sheet

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: FoodCatalogViewModel
    @State private var foodName = ""
    @State private var category: FoodCatalogItem.FoodCategory = .fruit

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nombre del alimento", text: $foodName)

                Picker("Categoría", selection: $category) {
                    Text("Fruta").tag(FoodCatalogItem.FoodCategory.fruit)
                    Text("Verdura").tag(FoodCatalogItem.FoodCategory.vegetable)
                    Text("Grano").tag(FoodCatalogItem.FoodCategory.grain)
                    Text("Proteína").tag(FoodCatalogItem.FoodCategory.protein)
                    Text("Lácteo").tag(FoodCatalogItem.FoodCategory.dairy)
                    Text("Otro").tag(FoodCatalogItem.FoodCategory.other)
                }
            }
            .navigationTitle("Agregar alimento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") {
                        Task {
                            await viewModel.addFood(name: foodName, category: category)
                            dismiss()
                        }
                    }
                    .disabled(foodName.isEmpty)
                }
            }
        }
    }
}
