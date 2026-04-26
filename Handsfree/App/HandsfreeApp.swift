import SwiftUI

@main
struct HandsfreeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var orchestrator: Orchestrator?
    private let status = AppStatus()

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController(appStatus: status)
        let orch = Orchestrator(status: status)
        orchestrator = orch
        orch.startup()
        Task { await UpdateChecker.shared.checkIfDue() }
    }
}
