import SwiftUI

struct SettingsView: View {
    @State private var openai: String = KeychainStore.get("openai_api_key") ?? ""
    @State private var anthropic: String = KeychainStore.get("anthropic_api_key") ?? ""
    @State private var saved: Bool = false
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left"); Text("Zurück") }
                    .buttonStyle(.plain)
                Spacer()
                Text("Einstellungen").font(.headline)
                Spacer().frame(width: 60)
            }

            GroupBox("API-Keys (Keychain)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI (Whisper)").font(.caption).foregroundStyle(.secondary)
                    SecureField("sk-…", text: $openai).textFieldStyle(.roundedBorder)
                    Text("Anthropic (Polished/Rage/Emoji)").font(.caption).foregroundStyle(.secondary)
                    SecureField("sk-ant-…", text: $anthropic).textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Speichern") {
                            if !openai.isEmpty { KeychainStore.set(openai, for: "openai_api_key") }
                            if !anthropic.isEmpty { KeychainStore.set(anthropic, for: "anthropic_api_key") }
                            saved = true
                        }
                        .keyboardShortcut(.defaultAction)
                        if saved {
                            Text("Gespeichert").font(.caption).foregroundStyle(.green)
                        }
                    }
                }.padding(8)
            }

            GroupBox("Berechtigungen") {
                VStack(alignment: .leading, spacing: 6) {
                    permissionRow("Mikrofon", hint: "Für Sprachaufnahme")
                    permissionRow("Accessibility", hint: "Für globale Hotkeys + Text-Einfügen")
                    permissionRow("Input Monitoring", hint: "Für Tastenerkennung")
                    Button("System Settings öffnen") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }.padding(8)
            }

            Spacer()
        }
        .padding(12)
        .frame(width: 320)
    }

    private func permissionRow(_ title: String, hint: String) -> some View {
        HStack {
            Image(systemName: "circle.dashed").foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text(title).font(.body)
                Text(hint).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
