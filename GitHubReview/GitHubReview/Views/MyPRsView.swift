import SwiftUI

struct MyPRsView: View {
    @EnvironmentObject var prVM: PRViewModel

    var body: some View {
        Group {
            if prVM.myPRGroups.isEmpty && !prVM.isLoading {
                ContentUnavailableView(
                    "No Open PRs",
                    systemImage: "checkmark.circle",
                    description: Text("You don't have any open pull requests.")
                )
            } else {
                List {
                    ForEach(prVM.myPRGroups) { group in
                        Section {
                            ForEach(group.prs) { pr in
                                PRRowView(pr: pr)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.caption2)
                                Text(group.repoName)
                                    .font(.caption.bold())
                                Spacer()
                                Text("\(group.prs.count)")
                                    .font(.caption2.monospaced())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(.blue.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}
