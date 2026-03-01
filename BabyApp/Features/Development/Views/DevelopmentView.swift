import SwiftUI

struct DevelopmentView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DevelopmentViewModel()
    @State private var selectedCategory: MilestoneDefinition.MilestoneCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Growth Summary
                    if let latest = viewModel.latestGrowth {
                        GrowthSummaryCard(record: latest)
                    }

                    // Milestone Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hitos del desarrollo")
                            .font(.title2)
                            .fontWeight(.bold)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                MilestoneCategoryChip(
                                    title: "Todos",
                                    isSelected: selectedCategory == nil
                                ) {
                                    selectedCategory = nil
                                }

                                ForEach(MilestoneDefinition.MilestoneCategory.allCases, id: \.self) { cat in
                                    MilestoneCategoryChip(
                                        title: categoryTitle(cat),
                                        isSelected: selectedCategory == cat
                                    ) {
                                        selectedCategory = cat
                                    }
                                }
                            }
                        }
                    }

                    // Milestones List
                    VStack(spacing: 8) {
                        ForEach(viewModel.filteredMilestones(category: selectedCategory)) { milestone in
                            MilestoneRow(
                                milestone: milestone,
                                isAchieved: viewModel.isAchieved(milestone.id),
                                babyAgeMonths: viewModel.babyAgeMonths
                            ) {
                                Task {
                                    await viewModel.toggleMilestone(milestone.id)
                                }
                            }
                        }
                    }

                    // Growth Chart Placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Curva de crecimiento")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Gráficas OMS próximamente")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Desarrollo")
            .task {
                await viewModel.loadData(baby: appState.currentBaby)
            }
        }
    }

    private func categoryTitle(_ cat: MilestoneDefinition.MilestoneCategory) -> String {
        switch cat {
        case .grossMotor: return "Motor grueso"
        case .fineMotor: return "Motor fino"
        case .language: return "Lenguaje"
        case .social: return "Social"
        case .cognitive: return "Cognitivo"
        }
    }
}

// MARK: - Growth Summary Card

struct GrowthSummaryCard: View {
    let record: GrowthRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Últimas medidas")
                .font(.headline)

            HStack(spacing: 16) {
                if let weight = record.weightKg {
                    GrowthMetric(
                        label: "Peso",
                        value: "\(String(format: "%.1f", weight)) kg",
                        percentile: record.weightPercentile
                    )
                }
                if let height = record.heightCm {
                    GrowthMetric(
                        label: "Talla",
                        value: "\(String(format: "%.1f", height)) cm",
                        percentile: record.heightPercentile
                    )
                }
                if let head = record.headCircumferenceCm {
                    GrowthMetric(
                        label: "PC",
                        value: "\(String(format: "%.1f", head)) cm",
                        percentile: record.headPercentile
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

struct GrowthMetric: View {
    let label: String
    let value: String
    let percentile: Double?

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            if let p = percentile {
                Text("P\(Int(p))")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Milestone Category Chip

struct MilestoneCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.pink : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: MilestoneDefinition
    let isAchieved: Bool
    let babyAgeMonths: Int
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isAchieved ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isAchieved ? .green : .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isAchieved)

                if let desc = milestone.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Age range badge
            Text("\(milestone.expectedMinMonths)-\(milestone.expectedMaxMonths)m")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ageRangeColor.opacity(0.15))
                .foregroundStyle(ageRangeColor)
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var ageRangeColor: Color {
        if isAchieved { return .green }
        if babyAgeMonths < milestone.expectedMinMonths { return .gray }
        if babyAgeMonths <= milestone.expectedMaxMonths { return .orange }
        return .red // Past expected range
    }
}

// MARK: - CaseIterable conformance

extension MilestoneDefinition.MilestoneCategory: CaseIterable {
    static var allCases: [MilestoneDefinition.MilestoneCategory] {
        [.grossMotor, .fineMotor, .language, .social, .cognitive]
    }
}
