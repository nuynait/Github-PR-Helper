import Foundation
import UserNotifications

enum NotificationService {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func sendNewPRNotification(prs: [PullRequest], isReviewRequest: Bool) {
        guard !prs.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if prs.count == 1, let pr = prs.first {
            if isReviewRequest {
                content.title = "New Review Request"
                content.body = "\(pr.user.login) requested your review on #\(pr.number): \(pr.title)"
            } else {
                content.title = "New Pull Request"
                content.body = "#\(pr.number): \(pr.title) in \(pr.repoFullName)"
            }
        } else {
            if isReviewRequest {
                content.title = "\(prs.count) New Review Requests"
                content.body = prs.map { "#\($0.number) \($0.title)" }.joined(separator: ", ")
            } else {
                content.title = "\(prs.count) New Pull Requests"
                content.body = prs.map { "#\($0.number) \($0.title)" }.joined(separator: ", ")
            }
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
