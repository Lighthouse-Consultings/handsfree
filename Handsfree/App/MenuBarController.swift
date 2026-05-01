import AppKit
import SwiftUI

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let appStatus: AppStatus

    init(appStatus: AppStatus) {
        self.appStatus = appStatus
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 380, height: 720)
        let host = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(appStatus)
                .environmentObject(LocalizationManager.shared)
        )
        // Let the hosting view's intrinsic size drive the popover size —
        // so switching between MenuBarView (short) and SettingsView (tall)
        // resizes the popover live instead of sticking on the initial size.
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Handsfree")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
