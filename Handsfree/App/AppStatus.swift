import SwiftUI

@MainActor
final class AppStatus: ObservableObject {
    enum State: Equatable { case notReady(String), ready, recording, transcribing, error(String) }

    @Published var state: State = .notReady("startup")
    @Published var activeMode: Mode?

    var statusText: String {
        switch state {
        case .notReady(let m):  return "Nicht bereit: \(m)"
        case .ready:            return "Bereit"
        case .recording:        return "Aufnahme…"
        case .transcribing:     return "Transkribiere…"
        case .error(let m):     return "Fehler: \(m)"
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
