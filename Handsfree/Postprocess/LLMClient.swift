import Foundation

struct LLMClient {
    let apiKey: String
    let model: String = "claude-sonnet-4-6"

    func process(text: String, mode: Mode, emojiDensity: Int = 2) async throws -> String {
        guard let system = systemPrompt(for: mode, emojiDensity: emojiDensity) else { return text }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": system,
            "messages": [["role": "user", "content": text]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw HandsfreeError.postprocess(String(data: data, encoding: .utf8) ?? "unknown")
        }
        struct Block: Decodable { let text: String? }
        struct R: Decodable { let content: [Block] }
        let decoded = try JSONDecoder().decode(R.self, from: data)
        return decoded.content.compactMap(\.text).joined()
    }

    private func systemPrompt(for mode: Mode, emojiDensity: Int) -> String? {
        switch mode {
        case .raw:
            return nil
        case .polished:
            return """
            Du bekommst gesprochenen deutschen Text. Formuliere ihn in geschriebenes Deutsch um:
            entferne Füllwörter, glätte Satzbau, behalte Bedeutung und Tonalität exakt bei.
            Gib NUR den umformulierten Text zurück, keine Kommentare.
            """
        case .rage:
            return """
            Du bekommst einen wütenden, gereizten deutschen Text. Formuliere ihn höflich, professionell
            und freundlich um, ohne die inhaltliche Botschaft zu verändern. Gib NUR den umformulierten
            Text zurück.
            """
        case .emoji:
            return """
            Du bekommst gesprochenen deutschen Text. Behalte ihn möglichst originalgetreu bei
            und streue passende Emojis ein — Dichte: \(emojiDensity) von 5 (1=sparsam, 5=sehr viele).
            Gib NUR den Text mit Emojis zurück.
            """
        }
    }
}
