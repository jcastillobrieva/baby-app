import SwiftUI

struct AddBabyView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddBabyViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 60))
                        .foregroundStyle(.pink)

                    Text("Datos del bebé")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 8)

                // Basic Info
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Información básica")

                    TextField("Nombre", text: $viewModel.firstName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.givenName)

                    TextField("Apellido (opcional)", text: $viewModel.lastName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.familyName)

                    DatePicker(
                        "Fecha de nacimiento",
                        selection: $viewModel.dateOfBirth,
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    Picker("Sexo", selection: $viewModel.sex) {
                        Text("Masculino").tag(Baby.Sex.male)
                        Text("Femenino").tag(Baby.Sex.female)
                    }
                    .pickerStyle(.segmented)
                }

                // Birth Measurements
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Medidas al nacer (opcional)")

                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text("Peso (kg)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("ej: 3.20", text: $viewModel.birthWeightKg)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }

                        VStack(alignment: .leading) {
                            Text("Talla (cm)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("ej: 50.0", text: $viewModel.birthHeightCm)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Perímetro cefálico (cm)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("ej: 34.5", text: $viewModel.birthHeadCm)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Tipo de sangre (opcional)", selection: $viewModel.bloodType) {
                        Text("No sé").tag("")
                        Text("A+").tag("A+")
                        Text("A-").tag("A-")
                        Text("B+").tag("B+")
                        Text("B-").tag("B-")
                        Text("AB+").tag("AB+")
                        Text("AB-").tag("AB-")
                        Text("O+").tag("O+")
                        Text("O-").tag("O-")
                    }
                }

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // Save Button
                Button {
                    Task {
                        let success = await viewModel.saveBaby(familyId: appState.currentFamilyId)
                        if success {
                            await appState.loadFamilyAndBaby()
                            dismiss()
                        }
                    }
                } label: {
                    Text(viewModel.isLoading ? "Guardando..." : "Guardar")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isValid ? .pink : .gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.isValid || viewModel.isLoading)
            }
            .padding(24)
        }
        .navigationTitle("Agregar bebé")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}
