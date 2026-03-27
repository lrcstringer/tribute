import AuthenticationServices
import SwiftUI

@Observable
@MainActor
class AuthenticationService: NSObject {
    static let shared = AuthenticationService()

    private(set) var isAuthenticated: Bool = false
    private(set) var userId: String?
    private(set) var displayName: String?
    private(set) var isLoading: Bool = false
    private(set) var error: String?

    private var signInContinuation: CheckedContinuation<ASAuthorization, Error>?

    override init() {
        super.init()
        let storedId = UserDefaults.standard.string(forKey: "tribute_user_id")
        userId = storedId
        isAuthenticated = storedId != nil
        displayName = UserDefaults.standard.string(forKey: "tribute_display_name")
    }

    func signInWithApple() async {
        isLoading = true
        error = nil

        do {
            let authorization = try await performAppleSignIn()

            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let authCodeData = credential.authorizationCode,
                  let authCode = String(data: authCodeData, encoding: .utf8) else {
                error = "Could not process Apple Sign In credentials"
                isLoading = false
                return
            }

            let fullName = credential.fullName
            let email = credential.email

            if let givenName = fullName?.givenName {
                let name = [givenName, fullName?.familyName].compactMap { $0 }.joined(separator: " ")
                if !name.isEmpty {
                    UserDefaults.standard.set(name, forKey: "tribute_display_name")
                    displayName = name
                }
            }

            let response = try await APIService.shared.signInWithApple(
                identityToken: identityToken,
                authorizationCode: authCode,
                fullName: fullName,
                email: email
            )

            userId = response.userId
            isAuthenticated = true

            if let serverName = response.displayName, !serverName.isEmpty {
                displayName = serverName
                UserDefaults.standard.set(serverName, forKey: "tribute_display_name")
            }

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func signOut() {
        APIService.shared.signOut()
        userId = nil
        isAuthenticated = false
        displayName = nil
        UserDefaults.standard.removeObject(forKey: "tribute_display_name")
    }

    private func performAppleSignIn() async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            signInContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }
}

extension AuthenticationService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            signInContinuation?.resume(returning: authorization)
            signInContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            signInContinuation?.resume(throwing: error)
            signInContinuation = nil
        }
    }
}
