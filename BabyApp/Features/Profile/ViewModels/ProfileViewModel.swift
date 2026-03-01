import Foundation
import Supabase

@Observable
final class ProfileViewModel {
    var familyMembers: [FamilyMember] = []
    var showInvite = false
    var showEditBaby = false

    private let supabase = SupabaseService.shared.client
    private let authService = AuthService()

    func loadFamily(familyId: UUID?) async {
        guard let familyId else { return }

        do {
            let members: [FamilyMember] = try await supabase
                .from("family_members")
                .select()
                .eq("family_id", value: familyId.uuidString)
                .execute()
                .value

            familyMembers = members
        } catch {
            // Keep existing
        }
    }

    func signOut() async {
        try? await authService.signOut()
    }
}
