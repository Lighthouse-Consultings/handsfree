import AppKit

// Phase 1 stub — Automode will implement CGEventTap on flagsChanged + keyDown
// to detect Fn + {Shift, Control, Option, Command} hold/release.
final class GlobalHotkeyManager {
    typealias Handler = (Mode, HotkeyPhase) -> Void
    enum HotkeyPhase { case begin, end }

    private let handler: Handler
    init(handler: @escaping Handler) { self.handler = handler }

    func start() {
        // TODO: install CGEventTap at .cghidEventTap with .flagsChanged mask.
    }
}
