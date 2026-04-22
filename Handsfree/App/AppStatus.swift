import SwiftUI

@MainActor
final class AppStatus: ObservableObject {
    enum State { case notReady, ready, recording, transcribing, error(String) }

    @Published var state: State = .notReady
    @Published var activeMode: Mode?

    var statusText: String {
        switch state {
        case .notReady:      return "Nicht bereit"
        case .ready:         return "Bereit"
        case .recording:     return "Aufnahme…"
        case .transcribing:  return "Transkribiere…"
        case .error(let m):  return "Fehler: \(m)"
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
