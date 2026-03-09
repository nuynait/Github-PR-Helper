import SwiftUI

@main
struct GitHubReviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("GitHub Review", id: "main") {
            ContentView()
                .environmentObject(appDelegate.authVM)
                .environmentObject(appDelegate.prVM)
                .frame(minWidth: 400, minHeight: 500)
        }
        .defaultSize(width: 480, height: 600)
    }
}
