import Foundation
import Supabase
import os

private let logger = Logger(subsystem: "com.babyapp", category: "auth")

@Observable
final class AuthService {
    private let supabase = SupabaseService.shared.client

    var currentUser: User?
    var isLoading = false

    // MARK: - Sign Up

    /// Creates a new account, a family, and adds user as admin member.
    func signUp(email: String, password: String, displayName: String, familyName: String) async throws {
        isLoading = true
        defer { isLoading = false }

        logger.info("Signing up user: \(email)")

        let authResponse = try await supabase.auth.signUp(
            email: email,
            password: password
        )

        guard let user = authResponse.user else {
            throw AuthError.signUpFailed
        }

        currentUser = user

        // Create family
        let family: Family = try await supabase
            .from("families")
            .insert(["name": familyName])
            .select()
            .single()
            .execute()
            .value

        // Add user as admin member
        try await supabase
            .from("family_members")
            .insert([
                "family_id": family.id.uuidString,
                "user_id": user.id.uuidString,
                "role": "admin",
                "display_name": displayName
            ])
            .execute()

        logger.info("Sign up complete for \(email), family: \(family.name)")
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        logger.info("Signing in user: \(email)")

        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )

        currentUser = session.user
        logger.info("Sign in complete for \(email)")
    }

    // MARK: - Sign Out

    func signOut() async throws {
        logger.info("Signing out")
        try await supabase.auth.signOut()
        currentUser = nil
    }

    // MARK: - Session

    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            logger.info("Session restored for user: \(session.user.email ?? "unknown")")
        } catch {
            logger.info("No active session to restore")
            currentUser = nil
        }
    }

    // MARK: - Family Invite

    func inviteMember(email: String, familyId: UUID, role: String = "member") async throws {
        guard let user = currentUser else { throw AuthError.notAuthenticated }

        try await supabase
            .from("family_invites")
            .insert([
                "family_id": familyId.uuidString,
                "invited_by": user.id.uuidString,
                "email": email,
                "role": role
            ])
            .execute()

        logger.info("Invited \(email) to family \(familyId)")
    }

    func acceptInvite(token: String) async throws {
        guard let user = currentUser else { throw AuthError.notAuthenticated }

        // Find the invite
        let invite: FamilyInvite = try await supabase
            .from("family_invites")
            .select()
            .eq("token", value: token)
            .eq("status", value: "pending")
            .single()
            .execute()
            .value

        // Add user to family
        try await supabase
            .from("family_members")
            .insert([
                "family_id": invite.familyId.uuidString,
                "user_id": user.id.uuidString,
                "role": invite.role,
                "display_name": user.email ?? "Member"
            ])
            .execute()

        // Mark invite as accepted
        try await supabase
            .from("family_invites")
            .update(["status": "accepted"])
            .eq("id", value: invite.id.uuidString)
            .execute()

        logger.info("Accepted invite to family \(invite.familyId)")
    }
}

// MARK: - Error Types

enum AuthError: LocalizedError {
    case signUpFailed
    case notAuthenticated
    case inviteExpired

    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "No se pudo crear la cuenta. Intenta de nuevo."
        case .notAuthenticated:
            return "Debes iniciar sesión primero."
        case .inviteExpired:
            return "La invitación ha expirado."
        }
    }
}

// MARK: - Invite Model

struct FamilyInvite: Codable, Identifiable, Sendable {
    let id: UUID
    let familyId: UUID
    let invitedBy: UUID
    let email: String
    let role: String
    let status: String
    let token: String
    let createdAt: Date
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case invitedBy = "invited_by"
        case email, role, status, token
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}
