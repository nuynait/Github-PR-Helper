import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

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
            } else {
                Button("Sign in with GitHub") {
                    authVM.startDeviceFlow()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Uses GitHub Device Flow - no password needed")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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
