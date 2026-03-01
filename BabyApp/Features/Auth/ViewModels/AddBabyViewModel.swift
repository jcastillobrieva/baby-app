import Foundation
import Supabase

@Observable
final class AddBabyViewModel {
    var firstName = ""
    var lastName = ""
    var dateOfBirth = Date()
    var sex: Baby.Sex = .male
    var birthWeightKg = ""
    var birthHeightCm = ""
    var birthHeadCm = ""
    var bloodType = ""

    var isLoading = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared.client

    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Save baby to Supabase. Returns true on success.
    func saveBaby(familyId: UUID?) async -> Bool {
        guard let familyId else {
            errorMessage = "No se encontró la familia. Cierra sesión e intenta de nuevo."
            return false
        }

        guard isValid else {
            errorMessage = "El nombre es obligatorio."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var params: [String: String] = [
                "family_id": familyId.uuidString,
                "first_name": firstName.trimmingCharacters(in: .whitespaces),
                "date_of_birth": DateFormatters.dateOnly.string(from: dateOfBirth),
                "sex": sex.rawValue
            ]

            let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)
            if !trimmedLast.isEmpty {
                params["last_name"] = trimmedLast
            }

            if let weight = Double(birthWeightKg), weight > 0 {
                params["birth_weight_kg"] = String(weight)
            }

            if let height = Double(birthHeightCm), height > 0 {
                params["birth_height_cm"] = String(height)
            }

            if let head = Double(birthHeadCm), head > 0 {
                params["birth_head_circumference_cm"] = String(head)
            }

            if !bloodType.isEmpty {
                params["blood_type"] = bloodType
            }

            try await supabase
                .from("babies")
                .insert(params)
                .execute()

            return true
        } catch {
            errorMessage = "No se pudo guardar. Intenta de nuevo."
            return false
        }
    }
}
