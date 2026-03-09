import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showPATEntry = false
    @State private var patInput = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("GitHub Review")
                .font(.title2.bold())

            if let userCode = authVM.userCode {
                VStack(spacing: 12) {
                    Text("Enter this code on GitHub:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(userCode)
                        .font(.system(.title, design: .monospaced).bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.fill.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Code copied to clipboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if authVM.isPolling {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Waiting for authorization...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let url = authVM.verificationURL {
                        Button("Open GitHub") {
                            if let u = URL(string: url) {
                                NSWorkspace.shared.open(u)
                            }
                        }
                        .buttonStyle(.link)
                    }
                }
            } else if showPATEntry {
                VStack(spacing: 14) {
                    VStack(spacing: 6) {
                        Text("Steps:")
                            .font(.subheadline.bold())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Click the button below to open GitHub")
                            Text("2. Select \"Generate new token (classic)\"")
                            Text("3. Give it a name and select these scopes:")

                            VStack(alignment: .leading, spacing: 2) {
                                Label("**repo** - access private repos & PRs", systemImage: "checkmark.square.fill")
                                Label("**read:org** - see org membership", systemImage: "checkmark.square.fill")
                            }
                            .padding(.leading, 12)
                            .foregroundStyle(.primary)

                            Text("4. Click \"Generate token\" and copy it")
                            Text("5. Paste it below")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Button("Open GitHub Token Settings") {
                        NSWorkspace.shared.open(URL(string: "https://github.com/settings/tokens")!)
                    }
                    .buttonStyle(.bordered)

                    SecureField("ghp_...", text: $patInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 280)
                        .onSubmit { authVM.signInWithPAT(patInput) }

                    Button("Sign In") {
                        authVM.signInWithPAT(patInput)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(patInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("Back to Device Flow") {
                        showPATEntry = false
                        patInput = ""
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            } else {
                VStack(spacing: 12) {
                    Button("Sign in with GitHub") {
                        authVM.startDeviceFlow()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("Uses GitHub Device Flow - no password needed")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Divider()
                        .frame(maxWidth: 200)

                    Button("Use Personal Access Token instead") {
                        showPATEntry = true
                    }
                    .buttonStyle(.link)
                    .font(.caption)

                    Text("Best for private org repos - no org approval needed")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if let error = authVM.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
        .padding(40)
        .frame(minWidth: 320, minHeight: 300)
    }
}
