import SwiftUI
import AppKit
import AVFoundation
import IOKit.hid

// MARK: - Live permission checks (shared with Settings)

enum PermissionCheck {
    static var microphone: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    static var accessibility: Bool {
        AXIsProcessTrustedWithOptions(nil)
    }

    static var inputMonitoring: Bool {
        IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    }

    static func openSettingsPane(_ pane: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Window plumbing

@MainActor
final class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    func showIfNeeded() {
        guard !Preferences.onboardingCompleted else { return }
        show()
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let host = NSHostingController(rootView: OnboardingView(onFinish: { [weak self] in
            Preferences.onboardingCompleted = true
            self?.window?.close()
            self?.window = nil
        }))
        let win = NSWindow(contentViewController: host)
        win.title = t("Willkommen bei Flinktext", "Welcome to Flinktext")
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.center()
        window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - View

struct OnboardingView: View {
    let onFinish: () -> Void

    @StateObject private var models = WhisperModelManager.shared
    @State private var micGranted = PermissionCheck.microphone
    @State private var axGranted = PermissionCheck.accessibility
    @State private var inputGranted = PermissionCheck.inputMonitoring
    // System Settings only shows the app in a pane after it asked once — track that.
    @State private var axRequested = false
    @State private var inputRequested = false

    private let poll = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private var recommendedModel: WhisperModel {
        ProcessInfo.processInfo.physicalMemory >= 16 * 1024 * 1024 * 1024 ? .turbo : .small
    }
    private var activeModelInstalled: Bool { models.isInstalled(Preferences.whisperModel) }
    private var allDone: Bool { micGranted && axGranted && inputGranted && activeModelInstalled }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            stepCard(
                index: 1,
                granted: micGranted,
                title: t("Mikrofon", "Microphone"),
                text: t("Für die Sprachaufnahme. macOS fragt einmal nach.",
                        "For voice recording. macOS asks once.")
            ) {
                Button(micGranted ? t("Erteilt", "Granted") : t("Zugriff anfordern", "Request access")) {
                    switch AVCaptureDevice.authorizationStatus(for: .audio) {
                    case .notDetermined:
                        AVCaptureDevice.requestAccess(for: .audio) { ok in
                            Task { @MainActor in micGranted = ok }
                        }
                    case .authorized:
                        micGranted = true
                    default:
                        // Previously denied — the prompt won't reappear, send them to the pane.
                        PermissionCheck.openSettingsPane("Privacy_Microphone")
                    }
                }
                .disabled(micGranted)
            }

            stepCard(
                index: 2,
                granted: axGranted,
                title: t("Bedienungshilfen", "Accessibility"),
                text: t("Für den globalen Hotkey und das Einfügen am Cursor. In den Systemeinstellungen den Schalter bei Flinktext aktivieren.",
                        "For the global hotkey and inserting text at the cursor. Enable the Flinktext toggle in System Settings.")
            ) {
                Button(axGranted ? t("Erteilt", "Granted") : t("Systemeinstellungen öffnen", "Open System Settings")) {
                    if !axRequested {
                        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
                        axRequested = true
                    }
                    PermissionCheck.openSettingsPane("Privacy_Accessibility")
                }
                .disabled(axGranted)
            }

            stepCard(
                index: 3,
                granted: inputGranted,
                title: t("Eingabeüberwachung", "Input Monitoring"),
                text: t("Für die Erkennung der Hotkey-Tasten. In den Systemeinstellungen den Schalter bei Flinktext aktivieren.",
                        "For detecting the hotkey chords. Enable the Flinktext toggle in System Settings.")
            ) {
                Button(inputGranted ? t("Erteilt", "Granted") : t("Systemeinstellungen öffnen", "Open System Settings")) {
                    if !inputRequested {
                        IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
                        inputRequested = true
                    }
                    PermissionCheck.openSettingsPane("Privacy_ListenEvent")
                }
                .disabled(inputGranted)
            }

            modelCard

            footer
        }
        .padding(20)
        .frame(width: 500)
        .onReceive(poll) { _ in
            micGranted = PermissionCheck.microphone
            axGranted = PermissionCheck.accessibility
            inputGranted = PermissionCheck.inputMonitoring
            models.refreshInstalled()
            // Selected model missing but another installed? Follow reality — avoids
            // "model X missing" errors when the user downloaded a different one.
            if !models.isInstalled(Preferences.whisperModel),
               let fallback = WhisperModel.allCases.first(where: { models.isInstalled($0) }) {
                activate(fallback)
            }
        }
        .onAppear { models.refreshInstalled() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(t("Willkommen bei Flinktext", "Welcome to Flinktext"))
                .font(.title2.bold())
            Text(t("Vier Schritte, dann diktierst du in jeder App: Hotkey halten, sprechen, loslassen.",
                   "Four steps and you can dictate in any app: hold the hotkey, speak, release."))
                .font(.callout).foregroundStyle(.secondary)
        }
    }

    private var modelCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: activeModelInstalled ? "checkmark.circle.fill" : "4.circle")
                        .font(.title2)
                        .foregroundStyle(activeModelInstalled ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t("Spracherkennungs-Modell", "Speech recognition model")).font(.body.weight(.medium))
                        Text(t("Läuft komplett lokal auf deinem Mac. Eines genügt — du kannst später wechseln.",
                               "Runs fully locally on your Mac. One is enough — you can switch later."))
                            .font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                ForEach(WhisperModel.allCases) { model in
                    modelRow(model)
                }
            }
            .padding(6)
        }
    }

    private func modelRow(_ model: WhisperModel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: Preferences.whisperModel == model && models.isInstalled(model)
                  ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("\(model.displayName) (\(model.sizeLabel))").font(.callout)
                    if model == recommendedModel {
                        Text(t("empfohlen für dein Gerät", "recommended for this device"))
                            .font(.caption2).padding(.horizontal, 5).padding(.vertical, 1)
                            .background(.green.opacity(0.15), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
                Text(model.subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if models.isInstalled(model) {
                if Preferences.whisperModel == model {
                    Text(t("Aktiv", "Active")).font(.caption).foregroundStyle(.green)
                } else {
                    Button(t("Verwenden", "Use")) { activate(model) }.controlSize(.small)
                }
            } else if models.isDownloading(model) {
                ProgressView(value: models.progress(for: model) ?? 0).frame(width: 90)
                Button(t("Abbrechen", "Cancel")) { models.cancelDownload(model) }.controlSize(.small)
            } else {
                Button(t("Laden", "Download")) {
                    activate(model)
                    models.startDownload(model)
                }.controlSize(.small)
            }
        }
        .padding(.leading, 34)
    }

    private func activate(_ model: WhisperModel) {
        Preferences.whisperModel = model
        Preferences.backend = .local
        Preferences.notifyChanged()
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let err = models.lastError {
                Text(err).font(.caption).foregroundStyle(.orange)
            }
            Divider()
            HStack(alignment: .center) {
                Text(t("Danach: rechte Wahltaste (⌥) halten, sprechen, loslassen.",
                       "Then: hold the right Option key (⌥), speak, release."))
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(t("Später", "Later"), action: onFinish)
                Button(t("Los geht's", "Let's go"), action: onFinish)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!allDone)
            }
        }
    }

    private func stepCard(index: Int, granted: Bool, title: String, text: String,
                          @ViewBuilder action: () -> some View) -> some View {
        GroupBox {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: granted ? "checkmark.circle.fill" : "\(index).circle")
                    .font(.title2)
                    .foregroundStyle(granted ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body.weight(.medium))
                    Text(text).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                action()
            }
            .padding(6)
        }
    }
}
