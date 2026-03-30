import Foundation
import AuthenticationServices

// MARK: - Kimlik dogrulama view model
// Email, Apple Sign-In ve oturum yonetimi — production implementasyon

@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared
    private let appleSignIn = AppleSignInService()

    init() {
        Task { await checkExistingSession() }
    }

    // Mevcut oturumu kontrol et
    func checkExistingSession() async {
        let restored = await supabase.restoreSession()
        await MainActor.run {
            isAuthenticated = restored
        }
    }

    // Email ile giris yap
    func signIn() async {
        guard validateInput() else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signInWithEmail(email, password: password)
            await MainActor.run {
                isAuthenticated = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = mapAuthError(error)
                isLoading = false
                HapticService.error()
            }
        }
    }

    // Email ile kayit ol
    func signUp() async {
        guard validateInput() else { return }

        guard password.count >= 8 else {
            errorMessage = "Sifre en az 8 karakter olmali"
            HapticService.error()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.signUpWithEmail(email, password: password)
            await MainActor.run {
                isAuthenticated = true
                isLoading = false
                HapticService.importComplete()
            }
        } catch {
            await MainActor.run {
                errorMessage = mapAuthError(error)
                isLoading = false
                HapticService.error()
            }
        }
    }

    // Apple ile giris yap
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await appleSignIn.signIn()
            try await supabase.signInWithApple(
                idToken: result.idToken,
                nonce: result.nonce
            )
            await MainActor.run {
                isAuthenticated = true
                isLoading = false
                HapticService.importComplete()
            }
        } catch {
            await MainActor.run {
                // Iptal edilmisse hata gosterme
                if case AppleSignInError.cancelled = error {
                    isLoading = false
                    return
                }
                errorMessage = error.localizedDescription
                isLoading = false
                HapticService.error()
            }
        }
    }

    // Cikis yap
    func signOut() async {
        do {
            try await supabase.signOut()
            await MainActor.run {
                isAuthenticated = false
                email = ""
                password = ""
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    // Hesabi sil
    func deleteAccount() async {
        isLoading = true
        do {
            try await supabase.deleteAccount()
            await MainActor.run {
                isAuthenticated = false
                email = ""
                password = ""
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Dogrulama

    private func validateInput() -> Bool {
        guard !email.isEmpty else {
            errorMessage = "Email adresi gerekli"
            HapticService.error()
            return false
        }

        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Gecerli bir email adresi girin"
            HapticService.error()
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Sifre gerekli"
            HapticService.error()
            return false
        }

        return true
    }

    // Auth hatalarini kullanici dostu mesajlara cevir
    private func mapAuthError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()

        if message.contains("invalid login credentials") || message.contains("invalid_credentials") {
            return "Email veya sifre hatali"
        }
        if message.contains("email not confirmed") {
            return "Email adresinizi dogrulayin"
        }
        if message.contains("user already registered") {
            return "Bu email zaten kayitli"
        }
        if message.contains("network") || message.contains("internet") {
            return "Internet baglantinizi kontrol edin"
        }
        if message.contains("too many requests") || message.contains("rate limit") {
            return "Cok fazla deneme. Lutfen bekleyin"
        }

        return "Bir hata olustu. Tekrar deneyin"
    }
}
