import Foundation
import os.log

@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    struct LatestRelease: Decodable, Equatable {
        let tagName: String
        let name: String
        let htmlURL: URL
        let body: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case htmlURL = "html_url"
            case body
        }
    }

    @Published private(set) var latest: LatestRelease?
    @Published private(set) var checking = false
    @Published var lastError: String?

    private let log = Logger(subsystem: "com.lighthouseconsultings.handsfree", category: "UpdateChecker")
    private let apiURL = URL(string: "https://api.github.com/repos/Lighthouse-Consultings/handsfree/releases/latest")!
    private let lastCheckKey = "handsfree.updateCheck.lastCheckUnix"
    private let cooldown: TimeInterval = 24 * 3600

    private lazy var session: URLSession = {
        // Ephemeral: no cookies, no shared cache, no credentials sent.
        URLSession(configuration: .ephemeral)
    }()

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    var hasUpdate: Bool {
        guard let latest else { return false }
        let latestSemver = latest.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        return Self.semverCompare(latestSemver, isNewerThan: currentVersion)
    }

    /// Background-friendly: respects user toggle and per-day cooldown.
    func checkIfDue() async {
        guard Preferences.updateCheckEnabled else { return }
        let last = UserDefaults.standard.double(forKey: lastCheckKey)
        if Date().timeIntervalSince1970 - last < cooldown { return }
        await check()
    }

    /// Always fires, ignoring cooldown. For the manual "Auf Updates prüfen"-Button.
    func check() async {
        guard !checking else { return }
        checking = true
        defer { checking = false }
        do {
            var req = URLRequest(url: apiURL)
            req.setValue("Handsfree/\(currentVersion)", forHTTPHeaderField: "User-Agent")
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            req.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            req.timeoutInterval = 8

            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                throw HandsfreeError.transcription("Update-Check HTTP \(code)")
            }
            let release = try JSONDecoder().decode(LatestRelease.self, from: data)
            self.latest = release
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
            self.lastError = nil
            log.info("update check ok, latest=\(release.tagName, privacy: .public)")
        } catch {
            self.lastError = error.localizedDescription
            log.error("update check failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func semverCompare(_ left: String, isNewerThan right: String) -> Bool {
        let l = left.split(separator: ".").compactMap { Int($0) }
        let r = right.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(l.count, r.count) {
            let lv = i < l.count ? l[i] : 0
            let rv = i < r.count ? r[i] : 0
            if lv != rv { return lv > rv }
        }
        return false
    }
}
