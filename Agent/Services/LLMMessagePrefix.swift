import Foundation

/// Shared helper for LLM provider services: prepend "PROJECT FOLDER: …"
/// to the newest user message so the folder stays visible in context.
/// Previously duplicated in OllamaService and OpenAICompatibleService.
enum LLMMessagePrefix {
    static func withFolderPrefix(_ messages: [[String: Any]], projectFolder: String) -> [[String: Any]] {
        guard !projectFolder.isEmpty else { return messages }
        let prefix = "PROJECT FOLDER: \(projectFolder)\n"
        var result = messages
        for i in stride(from: result.count - 1, through: 0, by: -1) {
            guard result[i]["role"] as? String == "user" else { continue }
            if let text = result[i]["content"] as? String {
                result[i]["content"] = prefix + text
            } else if var blocks = result[i]["content"] as? [[String: Any]],
                      let first = blocks.first, first["type"] as? String == "text",
                      let existing = first["text"] as? String
            {
                blocks[0]["text"] = prefix + existing
                result[i]["content"] = blocks
            }
            break
        }
        return result
    }
}
