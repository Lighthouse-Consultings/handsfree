import AppKit
import Carbon.HIToolbox

// HIGH-fix #1: Fn-modifier detection via CGEventTap is unreliable across
// external keyboards (firmware resolves Fn locally; Touch Bar / Globe key
// conflicts). Default chord is Right-Option + {Shift|Control|Option|Command}.
// Fn alternative is gated behind `useFnModifier` for built-in Apple keyboards.
final class GlobalHotkeyManager {
    typealias Handler = (Mode, HotkeyPhase) -> Void
    enum HotkeyPhase { case begin, end }

    private let handler: Handler
    private let useFnModifier: Bool
    private var monitor: Any?
    private var localMonitor: Any?
    private var activeMode: Mode?

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
        let trigger: NSEvent.ModifierFlags = useFnModifier ? .function : rightOptionPseudoFlag(keyCode: keyCode, flags: flags)
        let triggerActive = flags.contains(trigger)

        guard triggerActive else {
            if let mode = activeMode {
                handler(mode, .end)
                activeMode = nil
            }
            return
        }

        let mode: Mode?
        switch flags {
        case let f where f.contains(.shift):    mode = .raw
        case let f where f.contains(.control):  mode = .polished
        case let f where f.contains(.option) && !triggerIsOption(trigger): mode = .rage
        case let f where f.contains(.command):  mode = .emoji
        default: mode = nil
        }

        if let mode, activeMode != mode {
            activeMode = mode
            handler(mode, .begin)
        }
    }

    private func triggerIsOption(_ trigger: NSEvent.ModifierFlags) -> Bool {
        trigger.contains(.option)
    }

    // Right-Option is keyCode 61 for the physical key; detect by observing
    // the flagsChanged event that fired *for that keyCode*.
    private func rightOptionPseudoFlag(keyCode: UInt16, flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        // 61 = kVK_RightOption
        if keyCode == 61 && flags.contains(.option) { return .option }
        return []
    }
}
