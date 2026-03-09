import SwiftUI

struct PRRowView: View {
    let pr: PullRequest

    var body: some View {
        Button {
            if let url = pr.browserURL {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(pr.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        if pr.isDraft {
                            Text("Draft")
                                .font(.caption2.bold())
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(.gray.opacity(0.2))
                                .clipShape(Capsule())
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 4) {
                        Text("#\(pr.number)")
                            .font(.caption.monospaced())
                        Text("by \(pr.user.login)")
                            .font(.caption)
                        Text("·")
                            .font(.caption)
                        Text(pr.timeAgo)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}
