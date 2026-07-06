import Foundation

// Local LLM via Ollama. Assumes ollama serve is running on :11434.
struct OllamaClient {
    let model: String
    let host: URL

    init(model: String = "gemma4:latest", host: URL = URL(string: "http://127.0.0.1:11434")!) {
        self.model = model
        self.host = host
    }

    private static let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 60
        c.timeoutIntervalForResource = 180
        return URLSession(configuration: c)
    }()

    static func isReachable() async -> Bool {
        var req = URLRequest(url: URL(string: "http://127.0.0.1:11434/api/tags")!)
        req.timeoutInterval = 1.5
        do {
            let (_, resp) = try await session.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    func generate(system: String, user: String) async throws -> String {
        var request = URLRequest(url: host.appendingPathComponent("/api/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "model": model,
            "system": system,
            "prompt": user,
            "stream": false,
            "options": ["temperature": 0.4, "num_predict": 1024]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await Self.session.data(for: request)
        } catch let e as URLError where e.code == .cannotConnectToHost || e.code == .timedOut {
            throw HandsfreeError.postprocess(t(
                "Lokales Sprachmodell (Ollama) läuft nicht. Setup: Einstellungen → LLM → Ollama-Anleitung. Alternativ bewusst ein Cloud-Backend aktivieren.",
                "Local language model (Ollama) is not running. Setup: Settings → LLM → Ollama guide. Alternatively enable a cloud backend deliberately."))
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw HandsfreeError.postprocess("ollama: \(msg.prefix(200))")
        }
        struct R: Decodable { let response: String }
        return try JSONDecoder().decode(R.self, from: data).response
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
