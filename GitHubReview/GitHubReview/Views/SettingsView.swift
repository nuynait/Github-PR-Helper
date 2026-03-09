import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var prVM: PRViewModel
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var pollTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Get notified when new pull requests are created or when someone requests your review, so you never miss an important code review.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.secondary)

                            Text("Push Notifications")
                                .font(.subheadline)

                            Spacer()

                            if notificationStatus == .authorized {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Enabled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)

                                if notificationStatus == .notDetermined {
                                    Button("Enable") {
                                        NotificationService.requestPermission()
                                        // Re-check after a short delay
                                        Task {
                                            try? await Task.sleep(for: .seconds(1))
                                            await checkNotificationStatus()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                } else {
                                    Button("Open Settings") {
                                        openNotificationSettings()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Notifications")
                }

                Section {
                    HStack {
                        Text("Archived Repos")
                            .font(.subheadline)
                        Spacer()
                        Text("\(prVM.archivedRepos.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if prVM.archivedRepos.isEmpty {
                        Text("No archived repos. Right-click a repo header to archive it.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(prVM.archivedRepos.sorted(), id: \.self) { repo in
                            HStack {
                                Image(systemName: "archivebox")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(repo)
                                    .font(.caption)
                                Spacer()
                                Button("Unarchive") {
                                    prVM.unarchiveRepo(repo)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                    }
                } header: {
                    Text("Archived Repos")
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            pollTask = Task {
                while !Task.isCancelled {
                    await checkNotificationStatus()
                    try? await Task.sleep(for: .seconds(2))
                }
            }
        }
        .onDisappear {
            pollTask?.cancel()
        }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = settings.authorizationStatus
        }
    }

    private func openNotificationSettings() {
        // Open System Settings > Notifications for this app
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
