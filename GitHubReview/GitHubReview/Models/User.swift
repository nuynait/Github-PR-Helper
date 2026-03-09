import Foundation

struct GitHubUser: Codable, Identifiable, Equatable {
    let id: Int
    let login: String
    let avatarUrl: String
    let name: String?
}
