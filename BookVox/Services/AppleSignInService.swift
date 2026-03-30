import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Apple Sign-In servisi
// ASAuthorizationController ile Apple kimlik dogrulama

final class AppleSignInService: NSObject {

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var currentNonce: String?

    struct AppleSignInResult {
        let idToken: String
        let nonce: String
        let fullName: PersonNameComponents?
        let email: String?
    }

    // Apple Sign-In akisini baslat
    func signIn() async throws -> AppleSignInResult {
        let nonce = generateNonce()
        currentNonce = nonce
        let hashedNonce = sha256(nonce)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    // Rastgele nonce olustur
    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            // Fallback
            return (0..<length).map { _ in
                String(format: "%02x", UInt8.random(in: 0...255))
            }.joined()
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    // SHA256 hash
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce
        else {
            continuation?.resume(throwing: AppleSignInError.missingToken)
            continuation = nil
            return
        }

        let result = AppleSignInResult(
            idToken: idToken,
            nonce: nonce,
            fullName: credential.fullName,
            email: credential.email
        )

        continuation?.resume(returning: result)
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            continuation?.resume(throwing: AppleSignInError.cancelled)
        } else {
            continuation?.resume(throwing: AppleSignInError.failed(error.localizedDescription))
        }
        continuation = nil
    }
}

// MARK: - Hatalar

enum AppleSignInError: LocalizedError {
    case missingToken
    case cancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .missingToken: "Apple kimlik bilgileri alinamadi"
        case .cancelled: "Giris iptal edildi"
        case .failed(let msg): "Apple giris hatasi: \(msg)"
        }
    }
}
