import Foundation

struct WhisperClient {
    let apiKey: String
    let model: String = "gpt-4o-transcribe"

    // Max ~60s mono 16kHz WAV ≈ 2 MB. Reject anything larger to cap cost/memory.
    static let maxWavBytes = 4 * 1024 * 1024

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpShouldSetCookies = false
        return URLSession(configuration: config)
    }()

    func transcribe(wav: Data, language: String? = "de", prompt: String? = nil) async throws -> String {
        guard wav.count <= Self.maxWavBytes else {
            throw HandsfreeError.transcription("recording too large (> \(Self.maxWavBytes / 1024 / 1024) MB)")
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "handsfree-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        field("model", model)
        if let language { field("language", language) }
        if let prompt { field("prompt", prompt) }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(wav)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await Self.session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw HandsfreeError.transcription(msg.count > 200 ? String(msg.prefix(200)) + "…" : msg)
        }
        struct R: Decodable { let text: String }
        return try JSONDecoder().decode(R.self, from: data).text
    }
}

enum HandsfreeError: Error {
    case transcription(String)
    case postprocess(String)
    case injection(String)
    case missingAPIKey
    case recordingTooLong
}
