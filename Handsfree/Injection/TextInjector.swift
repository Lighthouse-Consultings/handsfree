import AppKit

enum TextInjector {
    // HIGH-fix #2: restore clipboard only AFTER target app consumed paste
    // (changeCount increment), with 1.5s hard timeout.
    static func insert(_ text: String) throws {
        let pb = NSPasteboard.general
        let beforeCount = pb.changeCount
        let saved = snapshot(pb)

        pb.clearContents()
        pb.setString(sanitize(text), forType: .string)
        let afterWrite = pb.changeCount

        try pasteViaCGEvent()

        Task { @MainActor in
            let start = Date()
            while pb.changeCount == afterWrite, Date().timeIntervalSince(start) < 1.5 {
                try? await Task.sleep(for: .milliseconds(50))
            }
            restore(pb, items: saved, skipIfChangedFrom: beforeCount + 1)
        }
    }

    private static func snapshot(_ pb: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        pb.pasteboardItems?.map { item in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                // Skip concealed/transient types — don't round-trip sensitive content.
                if type.rawValue.contains("concealed") || type.rawValue.contains("transient") { continue }
                if let data = item.data(forType: type) { dict[type] = data }
            }
            return dict
        } ?? []
    }

    private static func restore(_ pb: NSPasteboard, items: [[NSPasteboard.PasteboardType: Data]], skipIfChangedFrom expected: Int) {
        // Another app wrote to clipboard meanwhile — don't clobber.
        guard pb.changeCount == expected else { return }
        pb.clearContents()
        for dict in items {
            let item = NSPasteboardItem()
            for (type, data) in dict { item.setData(data, forType: type) }
            pb.writeObjects([item])
        }
    }

    // Strip ASCII control chars that could escape into target app unexpectedly.
    private static func sanitize(_ s: String) -> String {
        s.unicodeScalars.filter { scalar in
            let v = scalar.value
            // Keep tab (0x09), LF (0x0A), CR (0x0D); drop other C0 controls.
            if v < 0x20 { return v == 0x09 || v == 0x0A || v == 0x0D }
            if v == 0x7F { return false }
            return true
        }.reduce(into: "") { $0.append(Character($1)) }
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
