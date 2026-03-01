import Foundation

@Observable
final class SignUpViewModel {
    var displayName = ""
    var familyName = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var isAuthenticated = false
    var errorMessage: String?

    private let authService = AuthService()

    var isValid: Bool {
        !displayName.isEmpty &&
        !familyName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    func signUp() async {
        guard isValid else {
            if password != confirmPassword {
                errorMessage = "Las contraseñas no coinciden."
            } else if password.count < 6 {
                errorMessage = "La contraseña debe tener al menos 6 caracteres."
            } else {
                errorMessage = "Completa todos los campos."
            }
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName,
                familyName: familyName
            )
            isAuthenticated = true
        } catch {
            errorMessage = "No se pudo crear la cuenta. Intenta de nuevo."
        }
    }
}
