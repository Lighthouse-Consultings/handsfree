import Foundation

struct WhisperClient {
    let apiKey: String
    let model: String = "gpt-4o-transcribe"

    func transcribe(wav: Data, language: String? = "de", prompt: String? = nil) async throws -> String {
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

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw HandsfreeError.transcription(String(data: data, encoding: .utf8) ?? "unknown")
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
}
