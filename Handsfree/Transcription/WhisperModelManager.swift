import Foundation
import os.log

@MainActor
final class WhisperModelManager: NSObject, ObservableObject {
    static let shared = WhisperModelManager()

    struct DownloadState {
        var task: URLSessionDownloadTask
        var progress: Double
        var receivedBytes: Int64
        var totalBytes: Int64
    }

    @Published private(set) var installed: Set<WhisperModel> = []
    @Published private(set) var downloads: [WhisperModel: DownloadState] = [:]
    @Published var lastError: String?

    private let log = Logger(subsystem: "com.lighthouseconsultings.handsfree", category: "ModelManager")
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.waitsForConnectivity = true
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    override init() {
        super.init()
        refreshInstalled()
    }

    // MARK: - Filesystem

    static var userModelsDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".handsfree/models", isDirectory: true)
    }

    static let sharedModelsDirectory = URL(fileURLWithPath: "/Users/Shared/.handsfree/models", isDirectory: true)

    static func installedPath(for model: WhisperModel) -> String? {
        let candidates = [
            sharedModelsDirectory.appendingPathComponent(model.fileName).path,
            userModelsDirectory.appendingPathComponent(model.fileName).path
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }

    func isInstalled(_ model: WhisperModel) -> Bool {
        Self.installedPath(for: model) != nil
    }

    func refreshInstalled() {
        var found: Set<WhisperModel> = []
        for model in WhisperModel.allCases where Self.installedPath(for: model) != nil {
            found.insert(model)
        }
        installed = found
    }

    // MARK: - Download lifecycle

    func isDownloading(_ model: WhisperModel) -> Bool {
        downloads[model] != nil
    }

    func progress(for model: WhisperModel) -> Double? {
        downloads[model]?.progress
    }

    func receivedBytes(for model: WhisperModel) -> Int64? {
        downloads[model]?.receivedBytes
    }

    func startDownload(_ model: WhisperModel) {
        guard downloads[model] == nil else { return }
        lastError = nil

        do {
            try FileManager.default.createDirectory(at: Self.userModelsDirectory, withIntermediateDirectories: true)
        } catch {
            lastError = "Konnte ~/.handsfree/models/ nicht anlegen: \(error.localizedDescription)"
            return
        }

        let task = session.downloadTask(with: model.downloadURL)
        task.taskDescription = model.rawValue
        downloads[model] = DownloadState(task: task, progress: 0, receivedBytes: 0, totalBytes: model.approximateBytes)
        task.resume()
        log.info("start download \(model.rawValue, privacy: .public)")
    }

    func cancelDownload(_ model: WhisperModel) {
        guard let state = downloads[model] else { return }
        state.task.cancel()
        downloads[model] = nil
    }

    func delete(_ model: WhisperModel) {
        let userFile = Self.userModelsDirectory.appendingPathComponent(model.fileName).path
        if FileManager.default.fileExists(atPath: userFile) {
            do {
                try FileManager.default.removeItem(atPath: userFile)
                log.info("deleted \(model.rawValue, privacy: .public)")
            } catch {
                lastError = "Löschen fehlgeschlagen: \(error.localizedDescription)"
            }
        }
        refreshInstalled()
    }

    // MARK: - Delegate bridge

    fileprivate func model(for task: URLSessionTask) -> WhisperModel? {
        guard let raw = task.taskDescription else { return nil }
        return WhisperModel(rawValue: raw)
    }
}

extension WhisperModelManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didWriteData bytesWritten: Int64,
                                totalBytesWritten: Int64,
                                totalBytesExpectedToWrite: Int64) {
        let desc = downloadTask.taskDescription
        let total = totalBytesExpectedToWrite
        Task { @MainActor in
            guard let raw = desc, let model = WhisperModel(rawValue: raw) else { return }
            guard var state = self.downloads[model] else { return }
            let expected = total > 0 ? total : model.approximateBytes
            state.receivedBytes = totalBytesWritten
            state.totalBytes = expected
            state.progress = min(1.0, max(0.0, Double(totalBytesWritten) / Double(max(expected, 1))))
            self.downloads[model] = state
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                downloadTask: URLSessionDownloadTask,
                                didFinishDownloadingTo location: URL) {
        let desc = downloadTask.taskDescription
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("handsfree-dl-\(UUID().uuidString).bin")
        var moveError: String?
        do {
            try fm.moveItem(at: location, to: tmp)
        } catch {
            moveError = error.localizedDescription
        }

        Task { @MainActor in
            defer { try? fm.removeItem(at: tmp) }
            guard let raw = desc, let model = WhisperModel(rawValue: raw) else { return }
            if let err = moveError {
                self.lastError = "Download-Temp konnte nicht gesichert werden: \(err)"
                self.downloads[model] = nil
                return
            }

            let dest = Self.userModelsDirectory.appendingPathComponent(model.fileName)
            do {
                try fm.createDirectory(at: Self.userModelsDirectory, withIntermediateDirectories: true)
                if fm.fileExists(atPath: dest.path) {
                    try fm.removeItem(at: dest)
                }
                try fm.moveItem(at: tmp, to: dest)
                self.log.info("installed \(model.rawValue, privacy: .public) at \(dest.path, privacy: .public)")
            } catch {
                self.lastError = "Modell installieren fehlgeschlagen: \(error.localizedDescription)"
            }
            self.downloads[model] = nil
            self.refreshInstalled()
            NotificationCenter.default.post(name: Preferences.didChangeNotification, object: nil)
        }
    }

    nonisolated func urlSession(_ session: URLSession,
                                task: URLSessionTask,
                                didCompleteWithError error: Error?) {
        guard let error else { return }
        let nsErr = error as NSError
        if nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorCancelled { return }
        let desc = task.taskDescription
        let message = error.localizedDescription
        Task { @MainActor in
            guard let raw = desc, let model = WhisperModel(rawValue: raw) else { return }
            self.downloads[model] = nil
            self.lastError = "Download fehlgeschlagen (\(model.displayName)): \(message)"
            self.log.error("download failed \(model.rawValue, privacy: .public): \(message, privacy: .public)")
        }
    }
}
