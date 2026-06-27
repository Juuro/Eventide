import SwiftUI

/// Secondary destination pushed from the gear in Today's nav bar. The app has no
/// accounts, network, or sync, so this stays intentionally small — an About
/// section plus room to grow (reminders, export, appearance) later.
struct SettingsView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Version", value: version)
            } header: {
                Text("About")
            } footer: {
                Text("Eventide is a private, on-device evening reflection. Nothing leaves your phone.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
