import SwiftUI

struct ArchivedReposView: View {
    @EnvironmentObject var prVM: PRViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if prVM.archivedRepos.isEmpty {
                ContentUnavailableView(
                    "No Archived Repos",
                    systemImage: "archivebox",
                    description: Text("Right-click a repo to archive it.")
                )
            } else {
                List {
                    ForEach(prVM.archivedRepos.sorted(), id: \.self) { repo in
                        HStack {
                            Image(systemName: "archivebox")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(repo)
                                .font(.subheadline)
                            Spacer()
                            Button("Unarchive") {
                                prVM.unarchiveRepo(repo)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 360, minHeight: 200)
        .navigationTitle("Archived Repos")
    }
}
