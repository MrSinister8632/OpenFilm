import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareCodeView: View {
    let code: String
    let recipe: Recipe
    let onDismiss: () -> Void

    @State private var copied = false

    private var tokenOnly: String {
        code.hasPrefix("OPENFILM://") ? String(code.dropFirst("OPENFILM://".count)) : code
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // QR Code
                    if let qrImage = QRCodeGenerator.generate(from: code, size: 260) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                    }

                    // Code text
                    VStack(spacing: 8) {
                        Text("OPENFILM://")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text(tokenOnly)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal)

                    // Fingerprint
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal")
                            .font(.caption)
                        Text("Fingerprint: \(RecipeFingerprint.generate(for: recipe))")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .foregroundStyle(.secondary)

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: copyCode) {
                            Label(copied ? "Copied!" : "Copy Code", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.2), value: copied)

                        Button(action: shareSheet) {
                            Label("Share…", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Share Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }

    private func copyCode() {
        UIPasteboard.general.string = code
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
    }

    private func shareSheet() {
        let av = UIActivityViewController(activityItems: [code], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }
}
