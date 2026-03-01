import Foundation
import Supabase

@Observable
final class DevelopmentViewModel {
    var milestones: [MilestoneDefinition] = []
    var babyMilestones: [BabyMilestone] = []
    var latestGrowth: GrowthRecord?
    var babyAgeMonths = 0

    private var baby: Baby?
    private let supabase = SupabaseService.shared.client

    // MARK: - Load

    func loadData(baby: Baby?) async {
        guard let baby else { return }
        self.baby = baby
        self.babyAgeMonths = AgeCalculator.calculate(from: baby.dateOfBirth).totalMonths

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadMilestones() }
            group.addTask { await self.loadBabyMilestones(babyId: baby.id) }
            group.addTask { await self.loadGrowth(babyId: baby.id) }
        }
    }

    private func loadMilestones() async {
        do {
            let defs: [MilestoneDefinition] = try await supabase
                .from("milestone_definitions")
                .select()
                .order("sort_order")
                .execute()
                .value
            milestones = defs
        } catch {
            // Keep existing
        }
    }

    private func loadBabyMilestones(babyId: UUID) async {
        do {
            let achieved: [BabyMilestone] = try await supabase
                .from("baby_milestones")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .execute()
                .value
            babyMilestones = achieved
        } catch {
            // Keep existing
        }
    }

    private func loadGrowth(babyId: UUID) async {
        do {
            let records: [GrowthRecord] = try await supabase
                .from("growth_records")
                .select()
                .eq("baby_id", value: babyId.uuidString)
                .order("measured_at", ascending: false)
                .limit(1)
                .execute()
                .value
            latestGrowth = records.first
        } catch {
            // Keep existing
        }
    }

    // MARK: - Filter

    func filteredMilestones(category: MilestoneDefinition.MilestoneCategory?) -> [MilestoneDefinition] {
        guard let category else { return milestones }
        return milestones.filter { $0.category == category }
    }

    func isAchieved(_ milestoneId: UUID) -> Bool {
        babyMilestones.contains { $0.milestoneId == milestoneId && $0.achievedAt != nil }
    }

    // MARK: - Toggle

    func toggleMilestone(_ milestoneId: UUID) async {
        guard let baby else { return }

        if let existing = babyMilestones.first(where: { $0.milestoneId == milestoneId }) {
            // Toggle off: remove achieved date
            if existing.achievedAt != nil {
                do {
                    try await supabase
                        .from("baby_milestones")
                        .update(["achieved_at": "null"])
                        .eq("id", value: existing.id.uuidString)
                        .execute()

                    await loadBabyMilestones(babyId: baby.id)
                } catch {
                    // Handle error
                }
            }
        } else {
            // Toggle on: create with achieved date
            do {
                let userId = try await supabase.auth.session.user.id

                try await supabase
                    .from("baby_milestones")
                    .insert([
                        "baby_id": baby.id.uuidString,
                        "milestone_id": milestoneId.uuidString,
                        "achieved_at": DateFormatters.dateOnly.string(from: Date()),
                        "logged_by": userId.uuidString
                    ])
                    .execute()

                await loadBabyMilestones(babyId: baby.id)
            } catch {
                // Handle error
            }
        }
    }
}
