import AppKit

enum TextInjector {
    static func insert(_ text: String) throws {
        let pb = NSPasteboard.general
        let saved = pb.pasteboardItems?.compactMap { item -> (String, Data)? in
            guard let type = item.types.first, let data = item.data(forType: type) else { return nil }
            return (type.rawValue, data)
        } ?? []

        pb.clearContents()
        pb.setString(text, forType: .string)

        try pasteViaCGEvent()

        // Restore original clipboard after paste has been absorbed by the target app.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            pb.clearContents()
            for (type, data) in saved {
                pb.setData(data, forType: NSPasteboard.PasteboardType(type))
            }
        }
    }

    private static func pasteViaCGEvent() throws {
        let src = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 9 // 'v'
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true),
              let up   = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        else { throw HandsfreeError.injection("CGEvent create failed") }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
