import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Baby Info
                if let baby = appState.currentBaby {
                    Section("Bebé") {
                        HStack {
                            Image(systemName: "face.smiling")
                                .font(.largeTitle)
                                .foregroundStyle(.pink)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(baby.firstName) \(baby.lastName ?? "")")
                                    .font(.headline)

                                let age = AgeCalculator.calculate(from: baby.dateOfBirth)
                                Text(age.displayString)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        LabeledContent("Fecha de nacimiento") {
                            Text(DateFormatters.mediumDate.string(from: baby.dateOfBirth))
                        }

                        LabeledContent("Sexo") {
                            Text(baby.sex == .male ? "Masculino" : "Femenino")
                        }

                        if let weight = baby.birthWeightKg {
                            LabeledContent("Peso al nacer") {
                                Text("\(String(format: "%.2f", weight)) kg")
                            }
                        }

                        if let height = baby.birthHeightCm {
                            LabeledContent("Talla al nacer") {
                                Text("\(String(format: "%.1f", height)) cm")
                            }
                        }

                        Button("Editar datos del bebé") {
                            viewModel.showEditBaby = true
                        }
                    }
                }

                // Family
                Section("Familia") {
                    ForEach(viewModel.familyMembers) { member in
                        HStack {
                            Image(systemName: "person.circle")
                            VStack(alignment: .leading) {
                                Text(member.displayName)
                                    .font(.subheadline)
                                Text(member.role == .admin ? "Administrador" : "Miembro")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button("Invitar miembro") {
                        viewModel.showInvite = true
                    }
                }

                // Settings
                Section("Configuración") {
                    Toggle("Modo nocturno manual", isOn: Binding(
                        get: { appState.isNightMode },
                        set: { appState.isNightMode = $0 }
                    ))

                    NavigationLink("Recordatorios") {
                        Text("Configuración de recordatorios (próximamente)")
                    }

                    NavigationLink("Exportar datos") {
                        Text("Exportar CSV/PDF (próximamente)")
                    }
                }

                // Account
                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        Task { await appState.signOut() }
                    }
                }
            }
            .navigationTitle("Perfil")
            .task {
                await viewModel.loadFamily(familyId: appState.currentFamilyId)
            }
            .sheet(isPresented: $viewModel.showInvite) {
                InviteView(familyId: appState.currentFamilyId)
            }
            .sheet(isPresented: $viewModel.showEditBaby) {
                if let baby = appState.currentBaby {
                    EditBabyView(baby: baby)
                }
            }
        }
    }
}

// MARK: - Invite View

struct InviteView: View {
    let familyId: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false

    private let authService = AuthService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Invitar a un familiar")
                    .font(.title2)
                    .fontWeight(.bold)

                TextField("Email del familiar", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                Button {
                    Task {
                        guard let familyId else { return }
                        isLoading = true
                        try? await authService.inviteMember(email: email, familyId: familyId)
                        isLoading = false
                        dismiss()
                    }
                } label: {
                    Text("Enviar invitación")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(email.isEmpty || isLoading)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
