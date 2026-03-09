import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var prVM: PRViewModel
    @State private var showSettings = false

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                mainView
            } else {
                LoginView()
            }
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            TabView {
                MyPRsView()
                    .tabItem {
                        Label("My PRs", systemImage: "arrow.triangle.pull")
                    }
                    .badge(prVM.myPRCount)

                ReviewRequestsView()
                    .tabItem {
                        Label("Review Requests", systemImage: "eye")
                    }
                    .badge(prVM.reviewRequestCount)
            }

            statusBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if prVM.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    prVM.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")

                Menu {
                    if let user = authVM.currentUser {
                        Text("Signed in as \(user.login)")
                        Divider()
                    }
                    Button("Settings...") {
                        showSettings = true
                    }
                    Divider()
                    Button("Sign Out") {
                        prVM.stopPolling()
                        authVM.signOut()
                    }
                } label: {
                    Image(systemName: "person.circle")
                }
            }
        }
        .onAppear {
            if let token = authVM.token, let user = authVM.currentUser {
                prVM.configure(token: token, username: user.login)
            }
        }
        .onChange(of: authVM.currentUser) { _, newUser in
            if let token = authVM.token, let user = newUser {
                prVM.configure(token: token, username: user.login)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(prVM)
        }
    }

    private var statusBar: some View {
        HStack {
            if let error = prVM.error {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if let lastUpdated = prVM.lastUpdated {
                Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
