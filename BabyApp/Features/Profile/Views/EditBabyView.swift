import SwiftUI

struct EditBabyView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String
    @State private var lastName: String
    @State private var dateOfBirth: Date
    @State private var sex: Baby.Sex
    @State private var birthWeightKg: String
    @State private var birthHeightCm: String
    @State private var birthHeadCm: String
    @State private var bloodType: String
    @State private var notes: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let baby: Baby
    private let supabase = SupabaseService.shared.client

    init(baby: Baby) {
        self.baby = baby
        _firstName = State(initialValue: baby.firstName)
        _lastName = State(initialValue: baby.lastName ?? "")
        _dateOfBirth = State(initialValue: baby.dateOfBirth)
        _sex = State(initialValue: baby.sex)
        _birthWeightKg = State(initialValue: baby.birthWeightKg.map { String($0) } ?? "")
        _birthHeightCm = State(initialValue: baby.birthHeightCm.map { String($0) } ?? "")
        _birthHeadCm = State(initialValue: baby.birthHeadCircumferenceCm.map { String($0) } ?? "")
        _bloodType = State(initialValue: baby.bloodType ?? "")
        _notes = State(initialValue: baby.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información básica") {
                    TextField("Nombre", text: $firstName)
                    TextField("Apellido", text: $lastName)
                    DatePicker("Fecha de nacimiento", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                    Picker("Sexo", selection: $sex) {
                        Text("Masculino").tag(Baby.Sex.male)
                        Text("Femenino").tag(Baby.Sex.female)
                    }
                }

                Section("Medidas al nacer") {
                    HStack {
                        Text("Peso (kg)")
                        Spacer()
                        TextField("ej: 3.20", text: $birthWeightKg)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Talla (cm)")
                        Spacer()
                        TextField("ej: 50.0", text: $birthHeightCm)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("Perímetro cefálico (cm)")
                        Spacer()
                        TextField("ej: 34.5", text: $birthHeadCm)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    Picker("Tipo de sangre", selection: $bloodType) {
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

                Section("Notas") {
                    TextField("Notas adicionales...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Editar datos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await save() }
                    }
                    .disabled(firstName.isEmpty || isLoading)
                }
            }
        }
    }

    private func save() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var params: [String: String] = [
                "first_name": firstName,
                "date_of_birth": DateFormatters.dateOnly.string(from: dateOfBirth),
                "sex": sex.rawValue
            ]

            let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)
            params["last_name"] = trimmedLast.isEmpty ? "" : trimmedLast

            if let w = Double(birthWeightKg), w > 0 { params["birth_weight_kg"] = String(w) }
            if let h = Double(birthHeightCm), h > 0 { params["birth_height_cm"] = String(h) }
            if let hc = Double(birthHeadCm), hc > 0 { params["birth_head_circumference_cm"] = String(hc) }
            if !bloodType.isEmpty { params["blood_type"] = bloodType }
            if !notes.isEmpty { params["notes"] = notes }

            try await supabase
                .from("babies")
                .update(params)
                .eq("id", value: baby.id.uuidString)
                .execute()

            // Reload baby data in app state
            await appState.loadFamilyAndBaby()
            dismiss()
        } catch {
            errorMessage = "No se pudo guardar. Intenta de nuevo."
        }
    }
}
