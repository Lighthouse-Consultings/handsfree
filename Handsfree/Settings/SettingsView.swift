import SwiftUI

struct SettingsView: View {
    @State private var openai: String = KeychainStore.get("openai_api_key") ?? ""
    @State private var anthropic: String = KeychainStore.get("anthropic_api_key") ?? ""
    @State private var saved: Bool = false
    @State private var backend: TranscriptionBackend = Preferences.backend
    @State private var llmBackend: LLMBackend = Preferences.llmBackend
    @State private var styleGuide: String = Preferences.styleGuide
    @State private var selectedWhisperModel: WhisperModel = Preferences.whisperModel
    @ObservedObject private var modelManager = WhisperModelManager.shared
    let onBack: () -> Void

    private var localAvailable: Bool {
        modelManager.isInstalled(selectedWhisperModel) && LocalWhisperClient.detect() != nil
    }

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left"); Text("Zurück") }
                    .buttonStyle(.plain)
                Spacer()
                Text("Einstellungen").font(.headline)
                Spacer().frame(width: 60)
            }

            GroupBox("Transkription") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Backend", selection: $backend) {
                        Text("OpenAI API").tag(TranscriptionBackend.api)
                        Text("Lokal (whisper.cpp)").tag(TranscriptionBackend.local)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: backend) { _, new in Preferences.backend = new }

                    if backend == .local {
                        whisperModelSection
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
                        Text("Modell: gemma via http://127.0.0.1:11434 (~5 GB Download)")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Ollama-Setup kopieren (3 Befehle)") {
                            let cmd = """
                            brew install ollama
                            brew services start ollama
                            ollama pull gemma3
                            """
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(cmd, forType: .string)
                        }
                        .font(.caption)
                        Text("→ in Terminal einfügen, Enter. Lädt 5 GB Modell lokal.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }.padding(8)
            }

            GroupBox("Stil-Vorgaben (wird an KI-Modi mitgegeben)") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dauerhafte Anweisungen für Polished / Emoji / Compose. Beispiel: Immer Sie-Form. LHC-Brand-Voice. Keine Em-Dashes. Signatur: Beste Grüße, Nico.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $styleGuide)
                        .font(.body)
                        .frame(minHeight: 80)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
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
                            Preferences.styleGuide = styleGuide
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

            GroupBox("Über Handsfree") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: "https://cdn.bfldr.com/L672WKMM/as/kwkj9q4nwcrj2fht65973n5c/LhC_-_Logo_simple_-_white?auto=webp&format=png")) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFit()
                                    .frame(width: 72, height: 48)
                                    .padding(6)
                                    .background(Color(red: 0x0C/255.0, green: 0x2E/255.0, blue: 0x4E/255.0), in: RoundedRectangle(cornerRadius: 6))
                            default:
                                Text("LHC").font(.headline.bold()).foregroundStyle(.white)
                                    .frame(width: 72, height: 48)
                                    .background(Color(red: 0x0C/255.0, green: 0x2E/255.0, blue: 0x4E/255.0), in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Handsfree \(appVersion)")
                                .font(.headline)
                            Text("Struktur. Klarheit. Wirkung.")
                                .font(.caption).italic().foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    HStack(alignment: .top, spacing: 10) {
                        AsyncImage(url: URL(string: "https://cdn.bfldr.com/L672WKMM/as/7kmkgp596j4tt3m74wkbfsw/Bildschirmfoto_2024-01-15_um_194833?auto=webp&format=png")) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color(red: 0xC5/255.0, green: 0xA5/255.0, blue: 0x72/255.0), lineWidth: 1))
                            default:
                                Image(systemName: "person.crop.circle")
                                    .resizable().frame(width: 48, height: 48)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Nico Röpnack").font(.body)
                            Text("Lighthouse Consultings").font(.caption).foregroundStyle(.secondary)
                            Link("addvalue@lighthouseconsultings.com",
                                 destination: URL(string: "mailto:addvalue@lighthouseconsultings.com")!)
                                .font(.caption)
                            Link("+49 177 3472334",
                                 destination: URL(string: "tel:+491773472334")!)
                                .font(.caption)
                        }
                    }

                    HStack(spacing: 14) {
                        Link("Website", destination: URL(string: "https://lighthouseconsultings.de")!)
                        Link("GitHub", destination: URL(string: "https://github.com/nicoroepnack-star/handsfree")!)
                    }.font(.caption)

                    Text("© 2026 Lighthouse Consultings")
                        .font(.caption2).foregroundStyle(.secondary)
                }.padding(8)
            }

            Spacer()
        }
        .padding(12)
        .frame(width: 380)
        }
        .frame(maxHeight: 720)
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        return "v\(v)"
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

    // MARK: - Whisper model picker

    private var whisperModelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Modell", selection: $selectedWhisperModel) {
                ForEach(WhisperModel.allCases) { m in
                    Text("\(m.displayName) (\(m.sizeLabel))").tag(m)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedWhisperModel) { _, new in Preferences.whisperModel = new }

            Text(selectedWhisperModel.subtitle)
                .font(.caption2).foregroundStyle(.secondary)

            ForEach(WhisperModel.allCases) { model in
                whisperModelRow(model)
            }

            if let err = modelManager.lastError {
                Text(err).font(.caption2).foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func whisperModelRow(_ model: WhisperModel) -> some View {
        let installed = modelManager.isInstalled(model)
        let progress = modelManager.progress(for: model)
        let isSelected = model == selectedWhisperModel

        HStack(spacing: 10) {
            Image(systemName: installed ? "checkmark.circle.fill"
                                        : (progress != nil ? "arrow.down.circle" : "circle.dashed"))
                .foregroundStyle(installed ? .green : (progress != nil ? .blue : .secondary))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.displayName).font(.body.weight(isSelected ? .semibold : .regular))
                    Text(model.sizeLabel).font(.caption).foregroundStyle(.secondary)
                    if isSelected {
                        Text("ausgewählt").font(.caption2).padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                    }
                }
                if let p = progress {
                    ProgressView(value: p).progressViewStyle(.linear)
                    Text(downloadStatusText(for: model))
                        .font(.caption2).foregroundStyle(.secondary)
                } else if installed {
                    Text("vorhanden").font(.caption2).foregroundStyle(.green)
                } else {
                    Text("nicht installiert").font(.caption2).foregroundStyle(.secondary)
                }
            }

            Spacer()

            if progress != nil {
                Button("Abbrechen") { modelManager.cancelDownload(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            } else if installed {
                Button("Löschen") { modelManager.delete(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            } else {
                Button("Laden") { modelManager.startDownload(model) }
                    .buttonStyle(.borderedProminent).controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    private func downloadStatusText(for model: WhisperModel) -> String {
        guard let state = modelManager.downloads[model] else { return "" }
        let mb = Double(state.receivedBytes) / 1_000_000
        let totalMB = Double(state.totalBytes) / 1_000_000
        let pct = Int((state.progress * 100).rounded())
        return String(format: "%.0f / %.0f MB (%d %%)", mb, totalMB, pct)
    }
}
