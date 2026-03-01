import SwiftUI

struct SignUpView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SignUpViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Crear Cuenta")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    TextField("Tu nombre", text: $viewModel.displayName)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)

                    TextField("Nombre de la familia", text: $viewModel.familyName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Contraseña", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)

                    SecureField("Confirmar contraseña", text: $viewModel.confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        await viewModel.signUp()
                        if viewModel.isAuthenticated {
                            appState.isAuthenticated = true
                            dismiss()
                        }
                    }
                } label: {
                    Text("Crear Cuenta")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.isLoading || !viewModel.isValid)
            }
            .padding(32)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}
