import Foundation

enum AuthError: LocalizedError {
    case invalidResponse
    case deviceCodeExpired
    case networkError(Error)
    case tokenError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from GitHub"
        case .deviceCodeExpired: return "Device code expired. Please try again."
        case .networkError(let error): return error.localizedDescription
        case .tokenError(let msg): return msg
        }
    }
}

actor AuthService {
    private let session = URLSession.shared

    func requestDeviceCode() async throws -> DeviceCodeResponse {
        var request = URLRequest(url: URL(string: Constants.gitHubDeviceCodeURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id": Constants.gitHubClientID,
            "scope": Constants.oauthScopes
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(DeviceCodeResponse.self, from: data)
    }

    func pollForAccessToken(deviceCode: String, interval: Int) async throws -> String {
        let pollInterval = max(interval, 5)

        while true {
            try await Task.sleep(for: .seconds(pollInterval))

            var request = URLRequest(url: URL(string: Constants.gitHubAccessTokenURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = [
                "client_id": Constants.gitHubClientID,
                "device_code": deviceCode,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
            ]
            request.httpBody = try JSONEncoder().encode(body)

            let (data, _) = try await session.data(for: request)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let tokenResponse = try decoder.decode(AccessTokenResponse.self, from: data)

            if let token = tokenResponse.accessToken {
                return token
            }

            if let error = tokenResponse.error {
                switch error {
                case "authorization_pending":
                    continue
                case "slow_down":
                    try await Task.sleep(for: .seconds(5))
                    continue
                case "expired_token":
                    throw AuthError.deviceCodeExpired
                default:
                    throw AuthError.tokenError(tokenResponse.errorDescription ?? error)
                }
            }
        }
    }
}
