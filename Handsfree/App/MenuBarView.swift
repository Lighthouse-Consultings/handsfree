import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var status: AppStatus
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
            Divider()
            ForEach(Mode.allCases, id: \.self) { mode in
                ModeRow(mode: mode, isActive: status.activeMode == mode)
                Divider()
            }
            footer
        }
        .padding(.vertical, 8)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Text("Handsfree").font(.headline)
            Spacer()
            Circle().fill(status.statusColor).frame(width: 8, height: 8)
            Text(status.statusText).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            HStack {
                Button("Einstellungen") { showSettings = true }
                Spacer()
                Button("Beenden") { NSApp.terminate(nil) }
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
