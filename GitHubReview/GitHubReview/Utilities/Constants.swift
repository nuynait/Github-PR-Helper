import Foundation

enum Constants {
    // Loaded from Secrets.xcconfig via Info.plist at build time
    static let gitHubClientID: String = {
        guard let clientID = Bundle.main.infoDictionary?["GITHUB_CLIENT_ID"] as? String,
              !clientID.isEmpty,
              clientID != "REPLACE_WITH_YOUR_CLIENT_ID"
        else {
            fatalError("GITHUB_CLIENT_ID not set. Copy Secrets.xcconfig.example to Secrets.xcconfig and add your Client ID.")
        }
        return clientID
    }()

    static let gitHubAPIBaseURL = "https://api.github.com"
    static let gitHubDeviceCodeURL = "https://github.com/login/device/code"
    static let gitHubAccessTokenURL = "https://github.com/login/oauth/access_token"
    static let gitHubDeviceActivationURL = "https://github.com/login/device"

    static let oauthScopes = "repo"

    static let pollInterval: TimeInterval = 120 // 2 minutes
    static let keychainService = "com.github-review.token"
    static let keychainAccount = "github-oauth-token"
}
