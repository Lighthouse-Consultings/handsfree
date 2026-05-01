import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var status: AppStatus
    @EnvironmentObject var localization: LocalizationManager
    @ObservedObject private var updates = UpdateChecker.shared
    @State private var showSettings = false

    var body: some View {
        Group {
            if showSettings {
                SettingsView { showSettings = false }
            } else {
                main
            }
        }
    }

    private var main: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if showFullError {
                errorBanner
            }
            if updates.hasUpdate, let release = updates.latest {
                updateBanner(release: release)
            }
            Divider()
            ForEach(Mode.allCases, id: \.self) { mode in
                ModeRow(mode: mode, isActive: status.activeMode == mode)
                Divider()
            }
            footer
        }
        .padding(.vertical, 8)
        .frame(width: 380)
    }

    private func updateBanner(release: UpdateChecker.LatestRelease) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(Color(red: 0xC5/255.0, green: 0xA5/255.0, blue: 0x72/255.0))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(t("Update verfügbar:", "Update available:")) \(release.tagName)").font(.caption.weight(.semibold))
                Text("\(t("Aktuell:", "Current:")) v\(updates.currentVersion)").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Notes") { NSWorkspace.shared.open(release.htmlURL) }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(red: 0xC5/255.0, green: 0xA5/255.0, blue: 0x72/255.0).opacity(0.12))
    }

    private var showFullError: Bool {
        if case .error = status.state { return true }
        if case .notReady = status.state { return true }
        return false
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 0xC5/255.0, green: 0xA5/255.0, blue: 0x72/255.0))
            Text("Handsfree").font(.headline)
            Spacer()
            Circle().fill(status.statusColor).frame(width: 8, height: 8)
            Text(status.shortStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var errorBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(status.statusText)
                    .font(.caption.monospaced())
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                Button(t("Fehler kopieren", "Copy error")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(status.statusText, forType: .string)
                }
                .font(.caption)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.10))
    }

    private var footer: some View {
        VStack(spacing: 4) {
            HStack {
                Button(t("Einstellungen", "Settings")) { showSettings = true }
                Spacer()
                Button(t("Beenden", "Quit")) { NSApp.terminate(nil) }
            }
            HStack {
                Spacer()
                Text("© 2026 LHC")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}

private struct ModeRow: View {
    let mode: Mode
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode.symbol).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title).font(.body)
                Text(mode.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(mode.hotkeyLabel)
                .font(.caption.monospaced())
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? Color.accentColor.opacity(0.12) : .clear)
    }
}
