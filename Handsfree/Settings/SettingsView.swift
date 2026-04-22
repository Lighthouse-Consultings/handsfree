import SwiftUI

struct SettingsView: View {
    @State private var openai: String = KeychainStore.get("openai_api_key") ?? ""
    @State private var anthropic: String = KeychainStore.get("anthropic_api_key") ?? ""
    @State private var saved: Bool = false
    @State private var backend: TranscriptionBackend = Preferences.backend
    @State private var llmBackend: LLMBackend = Preferences.llmBackend
    @State private var localAvailable: Bool = LocalWhisperClient.detect() != nil
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

            GroupBox("Transkription") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Backend", selection: $backend) {
                        Text("OpenAI API").tag(TranscriptionBackend.api)
                        Text("Lokal (whisper.cpp)").tag(TranscriptionBackend.local)
                            .disabled(!localAvailable)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: backend) { _, new in Preferences.backend = new }

                    if backend == .local {
                        Label(
                            localAvailable ? "Modell: ggml-large-v3-turbo (~1,5 GB)"
                                           : "Modell fehlt — ~/.handsfree/models/",
                            systemImage: localAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(localAvailable ? .green : .orange)
                    }
                }.padding(8)
            }

            GroupBox("LLM (für Polished / Emoji / Compose)") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("LLM", selection: $llmBackend) {
                        Text("Anthropic API").tag(LLMBackend.anthropic)
                        Text("Lokal (Ollama)").tag(LLMBackend.ollama)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: llmBackend) { _, new in Preferences.llmBackend = new }

                    if llmBackend == .ollama {
                        Text("Modell: gemma4:latest via http://127.0.0.1:11434")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(8)
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
                            Preferences.notifyChanged()
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
