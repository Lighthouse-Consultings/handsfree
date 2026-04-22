import AppKit
import Carbon.HIToolbox

// Default trigger: Right-Option (keyCode 61) held + second modifier.
// Fn alternative is unreliable across keyboards (see SECURITY.md).
final class GlobalHotkeyManager {
    typealias Handler = (Mode, HotkeyPhase) -> Void
    enum HotkeyPhase { case begin, end }

    private let handler: Handler
    private let useFnModifier: Bool
    private var monitor: Any?
    private var localMonitor: Any?
    private var activeMode: Mode?
    private var rightOptionHeld = false

    init(handler: @escaping Handler, useFnModifier: Bool = false) {
        self.handler = handler
        self.useFnModifier = useFnModifier
    }

    func start() {
        let mask: NSEvent.EventTypeMask = [.flagsChanged]
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleFlags(event.modifierFlags, keyCode: event.keyCode)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handleFlags(event.modifierFlags, keyCode: event.keyCode)
            return event
        }
    }

    func stop() {
        [monitor, localMonitor].compactMap { $0 }.forEach(NSEvent.removeMonitor(_:))
        monitor = nil
        localMonitor = nil
        if let mode = activeMode {
            handler(mode, .end)
            activeMode = nil
        }
    }

    private func handleFlags(_ flags: NSEvent.ModifierFlags, keyCode: UInt16) {
        // Update trigger-held state. Right-Option emits flagsChanged with keyCode=61.
        // Fn emits flagsChanged with keyCode=63 and .function flag.
        if keyCode == 61 { rightOptionHeld = flags.contains(.option) }
        // If Option is released entirely (flags no longer contain .option), trigger must be off.
        if !flags.contains(.option) { rightOptionHeld = false }

        let triggerActive: Bool
        if useFnModifier {
            triggerActive = flags.contains(.function)
        } else {
            triggerActive = rightOptionHeld
        }

        guard triggerActive else {
            endActiveMode()
            return
        }

        // Determine which second modifier is held alongside the trigger.
        let mode: Mode?
        if flags.contains(.shift) {
            mode = .raw
        } else if flags.contains(.control) {
            mode = .polished
        } else if flags.contains(.command) {
            mode = .emoji
        } else if useFnModifier && flags.contains(.option) {
            // Fn + Option for rage when Fn is the trigger
            mode = .rage
        } else if !useFnModifier && keyCode == 58 {
            // 58 = kVK_Option (left option) — for Right-Option trigger, use Left-Option as Rage
            mode = flags.contains(.option) ? .rage : nil
        } else {
            mode = nil
        }

        if let mode {
            if activeMode != mode {
                endActiveMode()
                activeMode = mode
                handler(mode, .begin)
            }
        } else {
            // Trigger held but no valid second modifier yet — keep waiting, don't end.
        }
    }

    private func endActiveMode() {
        if let mode = activeMode {
            handler(mode, .end)
            activeMode = nil
        }
    }
}
