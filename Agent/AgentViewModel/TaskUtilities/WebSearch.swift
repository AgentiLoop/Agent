
@preconcurrency import Foundation
import AgentTools
import AgentAudit
import AgentMCP
import AgentD1F
import Cocoa




// MARK: - Task Utilities: Web Search

extension AgentViewModel {

    // MARK: - Web Search (forwarding to WebSearch extension)

    /// Perform a web search, trying backends in the user's drag-and-drop
    /// order from the Web Search popover (top = preferred). Backends with no
    /// key are skipped; on error the next one is tried. The last backend
    /// attempted is returned even if it errored.
    nonisolated static func performWebSearchForTask(query: String, apiKey: String, provider: APIProvider) async -> (String, WebSearchBackend) {
        let chain: [(WebSearchBackend, String)] = WebSearchBackend.order.compactMap { backend in
            if backend == .duckDuckGo { return (backend, "") }
            let key = backend == .tavily && !apiKey.isEmpty ? apiKey : (backend.storedKey ?? "")
            return key.isEmpty ? nil : (backend, key)
        }
        for (i, (backend, key)) in chain.enumerated() {
            let result: String
            switch backend {
            case .ollama: result = await performOllamaWebSearchInternal(query: query, apiKey: key)
            case .zAI: result = await performZAIWebSearchInternal(query: query, apiKey: key)
            case .specStream: result = await performSpecStreamSearchInternal(query: query, apiKey: key)
            case .exa: result = await performExaSearchInternal(query: query, apiKey: key)
            case .tavily: result = await performTavilySearchForTask(query: query, apiKey: key)
            case .duckDuckGo: result = await performDuckDuckGoSearchInternal(query: query)
            case .claude: result = "Error: Claude web search runs inside the Claude API"
            }
            let isFinal = !result.hasPrefix("Error:") || i == chain.count - 1
            await MainActor.run { WebSearchStatsStore.shared.record(query: query, backend: backend, result: result, isFinal: isFinal) }
            if isFinal { return (result, backend) }
        }
        return ("Error: no web search backend available", .duckDuckGo)
    }

    /// Calls Z.AI's /web_search endpoint (search-prime engine). Returns structured
    /// results. Used as Tavily replacement when user has a Z.AI API key configured.
    nonisolated private static func performZAIWebSearchInternal(query: String, apiKey: String) async -> String {
        guard !apiKey.isEmpty else { return "Error: Z.AI API key not set." }
        guard let url = URL(string: "https://api.z.ai/api/paas/v4/web_search") else {
            return "Error: Invalid Z.AI search URL"
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = llmAPITimeout
        let body: [String: Any] = [
            "search_engine": "search-prime",
            "search_query": query,
            "count": 10,
            "search_recency_filter": "noLimit",
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return "Error: Invalid response from Z.AI"
            }
            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                return "Error: Z.AI API returned \(httpResponse.statusCode): \(errorBody)"
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return "Error: Failed to parse Z.AI response"
            }
            guard let results = json["search_result"] as? [[String: Any]], !results.isEmpty else {
                return "No results found for: \(query)"
            }
            var output = ""
            for (i, result) in results.enumerated() {
                let title = result["title"] as? String ?? "Untitled"
                let resultUrl = result["link"] as? String ?? ""
                let content = result["content"] as? String ?? ""
                let media = result["media"] as? String ?? ""
                let publishDate = result["publish_date"] as? String ?? ""
                output += "\(i + 1). \(title)\n   \(resultUrl)\n"
                if !media.isEmpty || !publishDate.isEmpty {
                    let metaParts = [media, publishDate].filter { !$0.isEmpty }
                    output += "   [\(metaParts.joined(separator: " · "))]\n"
                }
                if !content.isEmpty {
                    output += "   \(content)\n"
                }
                output += "\n"
            }
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "Error: Z.AI web search failed: \(error.localizedDescription)"
        }
    }

    /// Universal keyless web search via DuckDuckGo HTML endpoint. No API key needed.
    /// Parses result rows with regex; extracts real URLs from DDG click-tracker links.
    nonisolated private static func performDuckDuckGoSearchInternal(query: String) async -> String {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return "Error: failed to encode query"
        }
        guard let url = URL(string: "https://html.duckduckgo.com/html/?q=\(encoded)") else {
            return "Error: failed to build DuckDuckGo URL"
        }
        var request = URLRequest(url: url)
        // Real browser UA — DDG serves a stripped-down or empty page to
        // obvious bots. Matches the same UA the keyless web_fetch tool uses.
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) "
            + "Version/17.0 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = llmAPITimeout
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return "Error: invalid response from DuckDuckGo"
            }
            guard (200..<400).contains(httpResponse.statusCode) else {
                return "Error: DuckDuckGo returned HTTP \(httpResponse.statusCode)"
            }
            guard let html = String(data: data, encoding: .utf8) else {
                return "Error: failed to decode DuckDuckGo response"
            }
            let results = parseDuckDuckGoHTML(html, limit: 10)
            if results.isEmpty {
                return "No results found for: \(query)"
            }
            var output = ""
            for (i, result) in results.enumerated() {
                output += "\(i + 1). \(result.title)\n   \(result.url)\n"
                if !result.snippet.isEmpty {
                    output += "   \(result.snippet)\n"
                }
                output += "\n"
            }
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "Error: DuckDuckGo web search failed: \(error.localizedDescription)"
        }
    }

    /// / Parse the HTML result page returned by html.duckduckgo.com. Each / result row exposes a `result__a` anchor for
    /// the title+URL and a / `result__snippet` element for the description. The href is wrapped / in DDG's click-tracker (`/l/?uddg=ENCODED_URL`) so we extract and / decode the `uddg` query parameter to get the real destination.
    nonisolated private static func parseDuckDuckGoHTML(_ html: String, limit: Int) -> [(title: String, url: String, snippet: String)] {
        // Match: <a class="result__a" href="HREF" ... >TITLE</a>
        let titlePattern = #"<a[^>]*class="[^"]*result__a[^"]*"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)</a>"#
        // Match: class="result__snippet" ...>SNIPPET</...>
        let snippetPattern = #"class="[^"]*result__snippet[^"]*"[^>]*>([\s\S]*?)</a>"#

        guard let titleRegex = try? NSRegularExpression(pattern: titlePattern, options: []),
              let snippetRegex = try? NSRegularExpression(pattern: snippetPattern, options: [])
        else {
            return []
        }

        let nsHtml = html as NSString
        let titleMatches = titleRegex.matches(in: html, range: NSRange(location: 0, length: nsHtml.length))
        let snippetMatches = snippetRegex.matches(in: html, range: NSRange(location: 0, length: nsHtml.length))

        var results: [(title: String, url: String, snippet: String)] = []
        for (i, match) in titleMatches.enumerated() where match.numberOfRanges > 2 {
            if results.count >= limit { break }
            let rawHref = nsHtml.substring(with: match.range(at: 1))
            let rawTitle = nsHtml.substring(with: match.range(at: 2))
            let resolvedURL = decodeDuckDuckGoHref(rawHref)
            let title = stripHTMLTags(rawTitle).trimmingCharacters(in: .whitespacesAndNewlines)
            var snippet = ""
            if i < snippetMatches.count, snippetMatches[i].numberOfRanges > 1 {
                let raw = nsHtml.substring(with: snippetMatches[i].range(at: 1))
                snippet = stripHTMLTags(raw).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if !title.isEmpty && !resolvedURL.isEmpty {
                results.append((title, resolvedURL, snippet))
            }
        }
        return results
    }

    /// / DDG wraps every outbound link in `/l/?uddg=ENCODED_REAL_URL&rut=...`. / Pull the `uddg` parameter and
    /// percent-decode it to recover the real / destination. Falls back to the raw href if there's no `uddg` param.
    nonisolated private static func decodeDuckDuckGoHref(_ href: String) -> String {
        let normalized = href.hasPrefix("//") ? "https:" + href : href
        guard let comps = URLComponents(string: normalized) else { return href }
        if let uddg = comps.queryItems?.first(where: { $0.name == "uddg" })?.value {
            return uddg.removingPercentEncoding ?? uddg
        }
        return normalized
    }

    /// / Lightweight HTML tag stripper for DDG result text. Result rows / contain `<b>` highlighting and stray entities
    /// — strip the markup / and decode the common entities so the LLM gets clean text.
    nonisolated private static func stripHTMLTags(_ s: String) -> String {
        var out = s.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        out = out
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        return out
    }

    nonisolated private static func performOllamaWebSearchInternal(query: String, apiKey: String) async -> String {
        guard !apiKey.isEmpty else { return "Error: Ollama API key not set. Add it in Settings." }
        guard let url = URL(string: "https://ollama.com/api/web_search") else { return "Error: Invalid Ollama search URL" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = llmAPITimeout
        let body: [String: Any] = ["query": query, "max_results": 5]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return "Error: Invalid response from Ollama" }
            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                return "Error: Ollama API returned \(httpResponse.statusCode): \(errorBody)"
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return "Error: Failed to parse Ollama response" }
            if let results = json["results"] as? [[String: Any]], !results.isEmpty {
                var output = ""
                for (i, result) in results.enumerated() {
                    let title = result["title"] as? String ?? "Untitled"
                    let resultUrl = result["url"] as? String ?? ""
                    let content = result["content"] as? String ?? result["snippet"] as? String ?? ""
                    output += "\(i + 1). \(title)\n   \(resultUrl)\n   \(content)\n\n"
                }
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let results = json["web_search_results"] as? [[String: Any]], !results.isEmpty {
                var output = ""
                for (i, result) in results.enumerated() {
                    let title = result["title"] as? String ?? "Untitled"
                    let resultUrl = result["url"] as? String ?? ""
                    let content = result["content"] as? String ?? result["snippet"] as? String ?? ""
                    output += "\(i + 1). \(title)\n   \(resultUrl)\n   \(content)\n\n"
                }
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return "No search results found for '\(query)'"
        } catch { return "Error: \(error.localizedDescription)" }
    }

    /// Calls Exa's /search endpoint (https://api.exa.ai/search). Exa is a
    /// neural/semantic web search API; the `auto` type lets the API pick
    /// neural vs keyword per query. We request both `text` (truncated) and
    /// `highlights` so the snippet logic can cascade through whichever
    /// content the API returns. The `x-exa-integration` header tags this
    /// integration so Exa can attribute usage.
    nonisolated static func performExaSearchInternal(query: String, apiKey: String) async -> String {
        guard !apiKey.isEmpty else { return "Error: Exa API key not set. Add it in Settings." }
        guard let url = URL(string: "https://api.exa.ai/search") else { return "Error: Invalid Exa URL" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("agent", forHTTPHeaderField: "x-exa-integration")
        request.timeoutInterval = llmAPITimeout
        let body: [String: Any] = [
            "query": query,
            "type": "auto",
            "numResults": 5,
            "contents": [
                "text": ["maxCharacters": 800],
                "highlights": ["numSentences": 2, "highlightsPerUrl": 2],
            ],
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return "Error: Invalid response from Exa" }
            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                return "Error: Exa API returned \(httpResponse.statusCode): \(errorBody)"
            }
            return formatExaResponse(data: data, query: query)
        } catch { return "Error: \(error.localizedDescription)" }
    }

    /// Decode an Exa /search response and render it in the same multi-line
    /// format used by the other providers. Exposed for unit tests so we can
    /// feed in a hardcoded JSON fixture without hitting the network.
    nonisolated static func formatExaResponse(data: Data, query: String) -> String {
        struct ExaSearchResponse: Decodable {
            let results: [ExaResult]
        }
        struct ExaResult: Decodable {
            let title: String?
            let url: String?
            let publishedDate: String?
            let author: String?
            let text: String?
            let highlights: [String]?
            let summary: String?
        }
        do {
            let decoded = try JSONDecoder().decode(ExaSearchResponse.self, from: data)
            if decoded.results.isEmpty { return "No search results found for '\(query)'" }
            var output = ""
            for (i, result) in decoded.results.enumerated() {
                let title = result.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? result.title! : "Untitled"
                let resultUrl = result.url ?? ""
                output += "\(i + 1). \(title)\n   \(resultUrl)\n"
                let metaParts = [result.author, result.publishedDate].compactMap { $0 }.filter { !$0.isEmpty }
                if !metaParts.isEmpty {
                    output += "   [\(metaParts.joined(separator: " · "))]\n"
                }
                let snippet = exaSnippet(highlights: result.highlights, summary: result.summary, text: result.text)
                if !snippet.isEmpty { output += "   \(snippet)\n" }
                output += "\n"
            }
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "Error: Failed to parse Exa response: \(error.localizedDescription)"
        }
    }

    /// Cascade through the content modes Exa may return. The API may return
    /// any combination of highlights/summary/text depending on the request
    /// and what was indexed for the page; pick the first one that's actually
    /// populated rather than assuming exactly one will be present.
    nonisolated static func exaSnippet(highlights: [String]?, summary: String?, text: String?) -> String {
        if let highlights, !highlights.isEmpty {
            let joined = highlights
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " … ")
            if !joined.isEmpty { return joined }
        }
        if let summary = summary?.trimmingCharacters(in: .whitespacesAndNewlines), !summary.isEmpty {
            return summary
        }
        if let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            return text
        }
        return ""
    }

    /// Calls SpecStream's Search API (GET https://api.specstream.ai/v1/web-search?q=…
    /// with a Bearer key). Results are in `data.sources` (title, url, snippet,
    /// published); `data.answer`, when present, is listed first.
    nonisolated static func performSpecStreamSearchInternal(query: String, apiKey: String) async -> String {
        guard !apiKey.isEmpty else { return "Error: SpecStream API key not set. Add it in Web Search settings." }
        var comps = URLComponents(string: "https://api.specstream.ai/v1/web-search")
        // speed=fast is SpecStream's $1-per-1,000 tier (the default tier is $5).
        comps?.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "speed", value: "fast")]
        guard let url = comps?.url else { return "Error: Invalid SpecStream URL" }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = llmAPITimeout
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return "Error: Invalid response from SpecStream" }
            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                return "Error: SpecStream API returned \(httpResponse.statusCode): \(errorBody)"
            }
            return formatSpecStreamResponse(data: data, query: query)
        } catch { return "Error: SpecStream web search failed: \(error.localizedDescription)" }
    }

    /// Render a SpecStream response in the same numbered format as the other providers.
    nonisolated static func formatSpecStreamResponse(data: Data, query: String) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Error: Failed to parse SpecStream response"
        }
        let payload = json["data"] as? [String: Any] ?? json
        let sources = payload["sources"] as? [[String: Any]] ?? []
        // answer is an object {value, page, seen_at}; null when the API isn't confident.
        let answerObj = payload["answer"] as? [String: Any]
        let answerValue = answerObj.flatMap { $0["value"] }.map { "\($0)" }?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let answerPage = answerObj?["page"] as? String ?? ""
        let answer = answerPage.isEmpty || answerValue.isEmpty ? answerValue : "\(answerValue) (\(answerPage))"
        if sources.isEmpty && answer.isEmpty { return "No search results found for '\(query)'" }
        var output = answer.isEmpty ? "" : "Answer: \(answer)\n\n"
        for (i, source) in sources.enumerated() {
            let title = source["title"] as? String ?? "Untitled"
            let resultUrl = source["url"] as? String ?? ""
            let snippet = source["snippet"] as? String ?? ""
            let published = source["published"] as? String ?? ""
            output += "\(i + 1). \(title)\n   \(resultUrl)\n"
            if !published.isEmpty { output += "   [\(published)]\n" }
            if !snippet.isEmpty { output += "   \(snippet)\n" }
            output += "\n"
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func performTavilySearchForTask(query: String, apiKey: String) async -> String {
        guard !apiKey.isEmpty else { return "Error: Tavily API key not set. Add it in Settings." }
        guard let url = URL(string: "https://api.tavily.com/search") else { return "Error: Invalid Tavily URL" }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = llmAPITimeout
        let body: [String: Any] = ["query": query, "max_results": 5]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return "Error: Invalid response from Tavily" }
            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                return "Error: Tavily API returned \(httpResponse.statusCode): \(errorBody)"
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else { return "Error: Failed to parse Tavily response" }
            if results.isEmpty { return "No search results found for '\(query)'" }
            var output = ""
            for (i, result) in results.enumerated() {
                let title = result["title"] as? String ?? "Untitled"
                let resultUrl = result["url"] as? String ?? ""
                let content = result["content"] as? String ?? ""
                output += "\(i + 1). \(title)\n   \(resultUrl)\n   \(content)\n\n"
            }
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch { return "Error: \(error.localizedDescription)" }
    }
}
