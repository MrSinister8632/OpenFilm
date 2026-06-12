import SwiftUI

struct SettingsTab: View {
    @AppStorage("exportFormat")  private var exportFormat:  ExportFormat  = .jpeg
    @AppStorage("exportQuality") private var exportQuality: ExportQuality = .full

    var body: some View {
        NavigationStack {
            Form {
                exportSection
                privacySection
                aboutSection
                openSourceSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Export defaults

    private var exportSection: some View {
        Section {
            Picker("Default Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases) { fmt in
                    Text(fmt.label).tag(fmt)
                }
            }

            Picker("Default Quality", selection: $exportQuality) {
                ForEach(ExportQuality.allCases) { q in
                    Text(q.label).tag(q)
                }
            }
        } header: {
            Text("Export Defaults")
        } footer: {
            Text("These can be overridden per-export.")
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section("Privacy") {
            infoRow(icon: "wifi.slash",         title: "Offline only",      detail: "No internet required")
            infoRow(icon: "person.slash",        title: "No account needed", detail: "Zero sign-up")
            infoRow(icon: "eye.slash",           title: "No analytics",      detail: "No tracking of any kind")
            infoRow(icon: "icloud.slash",        title: "No cloud upload",   detail: "Photos stay on device")
            infoRow(icon: "lock.shield",         title: "No subscriptions",  detail: "Free forever")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Platform")
                Spacer()
                Text("iOS \(UIDevice.current.systemVersion)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Open Source

    private var openSourceSection: some View {
        Section("Open Source") {
            VStack(alignment: .leading, spacing: 8) {
                Text("OpenFilm is free and open source software.")
                    .font(.subheadline)
                Text("Licensed under the MIT License. Contributions welcome.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            Label("View on GitHub", systemImage: "arrow.up.right.square")
                .foregroundStyle(Color.accentColor)

            Label("Report a Bug", systemImage: "ladybug")
                .foregroundStyle(Color.accentColor)

            Label("MIT License", systemImage: "doc.text")
        }
    }

    // MARK: - Helpers

    private func infoRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
