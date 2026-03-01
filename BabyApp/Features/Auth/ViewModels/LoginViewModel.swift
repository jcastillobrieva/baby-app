import Foundation

@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var isAuthenticated = false
    var errorMessage: String?

    private let authService = AuthService()

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Completa todos los campos."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = "No se pudo iniciar sesión. Verifica tus datos."
        }
    }
}
