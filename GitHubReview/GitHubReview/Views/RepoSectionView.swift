import SwiftUI

struct RepoSectionView: View {
    let group: PRGroup
    let badgeColor: Color
    @Binding var isExpanded: Bool
    let onArchive: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isHovering ? .primary : .tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.easeInOut(duration: 0.15), value: isExpanded)
                .frame(width: 10)

            Image(systemName: "folder.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(group.repoName)
                .font(.caption.bold())
                .lineLimit(1)

            Spacer()

            Text("\(group.prs.count)")
                .font(.caption2.monospaced())
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(badgeColor.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                isExpanded.toggle()
            }
        }
        .contextMenu {
            Button("Archive \(group.repoName)") {
                onArchive()
            }
        }
        .listRowSeparator(.hidden)

        if isExpanded {
            ForEach(group.prs) { pr in
                PRRowView(pr: pr)
                    .padding(.leading, 16)
            }
        }
    }
}
