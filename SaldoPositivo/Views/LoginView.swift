import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel

    @State private var authMode: AuthMode = .login
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible = false

    private enum AuthMode {
        case login
        case register
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Image("SaldoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190, height: 190)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(spacing: 2) {
                    Text("Personal and shared wallets.")
                    Text("All in one trustable place.")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 0)
                .padding(.bottom, 30)

                VStack(spacing: 24) {
                    underlineField(
                        placeholder: "Enter email",
                        text: $email,
                        isSecure: false
                    )

                    underlineField(
                        placeholder: "Enter password",
                        text: $password,
                        isSecure: true
                    )
                }

                Button {
                    Task {
                        await sessionViewModel.signIn(with: .email)
                    }
                } label: {
                    Text(authMode == .login ? "Login" : "Create Account")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSubmit ? Color.green : Color.white.opacity(0.12))
                        .foregroundStyle(canSubmit ? .black : Color.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!canSubmit || sessionViewModel.isLoading)
                .padding(.top, 4)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        authMode = authMode == .login ? .register : .login
                    }
                } label: {
                    Text(authMode == .login ? "No account? Create one" : "Already have an account? Login")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)

                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                    Text("Or use")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.7))
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                }
                .padding(.top, 4)

                HStack(spacing: 24) {
                    Spacer()
                    socialIconButton(provider: .google)
                    socialIconButton(provider: .apple)
                    Spacer()
                }

                if let errorMessage = sessionViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                Spacer()

                Text("By continuing, you agree to the Terms of Use and Privacy Policy.")
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 34)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .overlay {
            if sessionViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private func underlineField(
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool
    ) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if isSecure {
                    Group {
                        if isPasswordVisible {
                            TextField(placeholder, text: text)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField(placeholder, text: text)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                    .foregroundStyle(.white)
                    .font(.title3)

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .foregroundStyle(.white)
                        .font(.title3)
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func socialIconButton(provider: AuthProvider) -> some View {
        Button {
            Task {
                await sessionViewModel.signIn(with: provider)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 62, height: 62)

                if provider == .apple {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.black)
                } else {
                    Text("G")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
        }
        .disabled(sessionViewModel.isLoading)
    }
}

#Preview {
    LoginView()
        .environmentObject(AppSessionViewModel())
}
