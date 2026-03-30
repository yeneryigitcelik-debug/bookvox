import SwiftUI
import AuthenticationServices

// MARK: - Giris ekrani

struct LoginView: View {
    @Bindable var authVM: AuthViewModel
    @State private var isSignUp = false
    @State private var logoScale = 0.8
    @State private var contentOpacity = 0.0

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: DS.Spacing.xxl) {
                    Spacer(minLength: geo.size.height * 0.08)

                    // Logo
                    VStack(spacing: DS.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 110, height: 110)

                            Circle()
                                .fill(Color.accentColor.opacity(0.06))
                                .frame(width: 140, height: 140)

                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.bookVoxAccent)
                                .symbolEffect(.pulse, options: .repeating.speed(0.3))
                        }
                        .scaleEffect(logoScale)

                        Text("BookVox")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("Kitaplarini sesle kesfet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Apple Sign-In
                    SignInWithAppleButton(
                        isSignUp ? .signUp : .signIn,
                        onRequest: { $0.requestedScopes = [.fullName, .email] },
                        onCompletion: { _ in Task { await authVM.signInWithApple() } }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .padding(.horizontal, DS.Spacing.xxxl)

                    // Ayirici
                    divider

                    // Email form
                    VStack(spacing: DS.Spacing.md) {
                        TextField("Email", text: $authVM.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .modifier(FieldStyle())

                        SecureField("Sifre", text: $authVM.password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .modifier(FieldStyle())
                    }
                    .padding(.horizontal, DS.Spacing.xxl)

                    // Hata
                    ErrorBanner(message: authVM.errorMessage)
                        .padding(.horizontal, DS.Spacing.xxl)

                    // Buton
                    Button {
                        Task { isSignUp ? await authVM.signUp() : await authVM.signIn() }
                    } label: {
                        Group {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Kayit Ol" : "Giris Yap")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    }
                    .disabled(authVM.isLoading)
                    .padding(.horizontal, DS.Spacing.xxl)

                    // Toggle
                    Button(isSignUp ? "Zaten hesabim var" : "Yeni hesap olustur") {
                        withAnimation(DS.Anim.smooth) {
                            isSignUp.toggle()
                            authVM.errorMessage = nil
                        }
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.accent)

                    Spacer(minLength: DS.Spacing.xxxl)

                    // Footer
                    HStack(spacing: DS.Spacing.lg) {
                        Link("Gizlilik", destination: Constants.App.websiteURL)
                        Text("·").foregroundStyle(.quaternary)
                        Link("Kosullar", destination: Constants.App.websiteURL)
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, DS.Spacing.sm)
                }
                .frame(minHeight: geo.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { logoScale = 1.0 }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) { contentOpacity = 1.0 }
        }
    }

    private var divider: some View {
        HStack(spacing: DS.Spacing.md) {
            Rectangle().fill(.quaternary).frame(height: 0.5)
            Text("veya email ile")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Rectangle().fill(.quaternary).frame(height: 0.5)
        }
        .padding(.horizontal, DS.Spacing.xxxl)
    }
}

// MARK: - Text field stili

private struct FieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DS.Spacing.lg)
            .frame(height: 48)
            .background(.fill.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}

#Preview { LoginView(authVM: AuthViewModel()) }
