import SwiftUI

@MainActor
final class AppStatus: ObservableObject {
    enum State: Equatable { case notReady(String), ready, recording, transcribing, error(String) }

    @Published var state: State = .notReady("startup")
    @Published var activeMode: Mode?

    var statusText: String {
        switch state {
        case .notReady(let m):  return "\(t("Nicht bereit:", "Not ready:")) \(m)"
        case .ready:            return t("Bereit", "Ready")
        case .recording:        return t("Aufnahme…", "Recording…")
        case .transcribing:     return t("Transkribiere…", "Transcribing…")
        case .error(let m):     return "\(t("Fehler:", "Error:")) \(m)"
        }
    }

    // Short label for the header line — details shown in the error banner below.
    var shortStatusText: String {
        switch state {
        case .notReady:     return t("Nicht bereit", "Not ready")
        case .ready:        return t("Bereit", "Ready")
        case .recording:    return t("Aufnahme…", "Recording…")
        case .transcribing: return t("Transkribiere…", "Transcribing…")
        case .error:        return t("Fehler", "Error")
        }
    }

    var statusColor: Color {
        switch state {
        case .notReady:     return .gray
        case .ready:        return .green
        case .recording:    return .red
        case .transcribing: return .yellow
        case .error:        return .orange
        }
    }
}
