import SwiftUI

/// Standalone view for accepting a family invite via token code.
/// Shown when a second parent signs up and enters the invite code.
struct AcceptInviteView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var success = false

    private let authService = AuthService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.pink)

                Text("Unirte a una familia")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Ingresa el código de invitación que recibiste del otro padre.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                TextField("Código de invitación", text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .padding(.horizontal, 32)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if success {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                        Text("Te uniste a la familia exitosamente!")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }

                Button {
                    Task { await acceptInvite() }
                } label: {
                    Text(isLoading ? "Procesando..." : "Aceptar invitación")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inviteCode.isEmpty ? .gray : .pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(inviteCode.isEmpty || isLoading || success)
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationTitle("Invitación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func acceptInvite() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.acceptInvite(token: inviteCode.trimmingCharacters(in: .whitespaces))
            success = true

            // Reload family and baby data
            await appState.loadFamilyAndBaby()

            // Auto-dismiss after brief delay
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch {
            errorMessage = "Código inválido o expirado. Verifica e intenta de nuevo."
        }
    }
}
