import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: GitHubUser?
    @Published var userCode: String?
    @Published var verificationURL: String?
    @Published var isPolling = false
    @Published var error: String?

    private let authService = AuthService()
    private var pollTask: Task<Void, Never>?

    var token: String? {
        KeychainService.loadToken()
    }

    init() {
        if let token = KeychainService.loadToken() {
            isAuthenticated = true
            Task { await fetchUser(token: token) }
        }
    }

    func startDeviceFlow() {
        error = nil
        pollTask?.cancel()

        pollTask = Task {
            do {
                let deviceCode = try await authService.requestDeviceCode()

                self.userCode = deviceCode.userCode
                self.verificationURL = deviceCode.verificationUri

                // Open browser for user
                if let url = URL(string: deviceCode.verificationUri) {
                    NSWorkspace.shared.open(url)
                }

                // Copy code to clipboard
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(deviceCode.userCode, forType: .string)

                self.isPolling = true
                let token = try await authService.pollForAccessToken(
                    deviceCode: deviceCode.deviceCode,
                    interval: deviceCode.interval
                )

                try KeychainService.save(token: token)
                self.isPolling = false
                self.isAuthenticated = true
                self.userCode = nil
                self.verificationURL = nil

                await fetchUser(token: token)
            } catch {
                if !Task.isCancelled {
                    self.isPolling = false
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        pollTask?.cancel()
        KeychainService.deleteToken()
        isAuthenticated = false
        currentUser = nil
        userCode = nil
        verificationURL = nil
        isPolling = false
    }

    private func fetchUser(token: String) async {
        let service = GitHubService(token: token)
        do {
            currentUser = try await service.fetchCurrentUser()
        } catch is GitHubAPIError {
            // Token may be invalid
            signOut()
        } catch {}
    }
}
