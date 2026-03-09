import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()

    let authVM = AuthViewModel()
    let prVM = PRViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        observeBadgeCounts()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateButton(button, reviewCount: 0, myPRCount: 0)
            button.action = #selector(statusItemClicked)
            button.target = self
        }
    }

    @objc private func statusItemClicked() {
        if let window = NSApp.windows.first(where: { $0.title.contains("GitHub Review") || $0.isKeyWindow }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Open a new window if none exists
            for window in NSApp.windows {
                if window.level == .normal {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func observeBadgeCounts() {
        prVM.$reviewRequests
            .combineLatest(prVM.$myPRs)
            .receive(on: RunLoop.main)
            .sink { [weak self] reviews, myPRs in
                guard let button = self?.statusItem.button else { return }
                self?.updateButton(button, reviewCount: reviews.count, myPRCount: myPRs.count)
            }
            .store(in: &cancellables)
    }

    private func updateButton(_ button: NSStatusBarButton, reviewCount: Int, myPRCount: Int) {
        let attributed = NSMutableAttributedString()

        // GitHub-style icon using SF Symbol
        let iconAttachment = NSTextAttachment()
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let icon = NSImage(systemSymbolName: "arrow.triangle.pull", accessibilityDescription: "GitHub Review")?
            .withSymbolConfiguration(config) {
            iconAttachment.image = icon
        }
        attributed.append(NSAttributedString(attachment: iconAttachment))

        if reviewCount > 0 {
            attributed.append(NSAttributedString(string: " "))
            let reviewBadge = NSAttributedString(
                string: "\(reviewCount)",
                attributes: [
                    .foregroundColor: NSColor.systemOrange,
                    .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
                ]
            )
            attributed.append(reviewBadge)
        }

        if myPRCount > 0 {
            attributed.append(NSAttributedString(string: " "))
            let myPRBadge = NSAttributedString(
                string: "\(myPRCount)",
                attributes: [
                    .foregroundColor: NSColor.systemBlue,
                    .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
                ]
            )
            attributed.append(myPRBadge)
        }

        button.attributedTitle = attributed
    }
}
