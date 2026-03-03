import Foundation

enum LogParser {
    /// Parses a single .jsonl session file and returns the LAST token_count's total_token_usage.
    /// total_token_usage is cumulative within a session, so only the last event gives the session total.
    static func parseSessionFile(at url: URL) -> (usage: UsageDetail, rateLimits: RateLimits?)? {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return nil }

        let decoder = JSONDecoder()
        var lastUsage: UsageDetail?
        var lastRateLimits: RateLimits?

        for line in content.components(separatedBy: .newlines) where !line.isEmpty {
            guard let lineData = line.data(using: .utf8),
                  let logLine = try? decoder.decode(LogLine.self, from: lineData),
                  logLine.type == "event_msg",
                  logLine.payload.type == "token_count",
                  let info = logLine.payload.info else { continue }

            lastUsage = info.totalTokenUsage
            lastRateLimits = logLine.payload.rateLimits
        }

        guard let usage = lastUsage else { return nil }
        return (usage, lastRateLimits)
    }

    /// Aggregates token usage across multiple session files.
    /// Files are sorted chronologically, so the last one has the most recent rate limits.
    static func aggregate(sessionFiles: [URL]) -> AggregatedUsage {
        var result = AggregatedUsage.zero

        for file in sessionFiles {
            guard let parsed = parseSessionFile(at: file) else { continue }
            result.add(parsed.usage)

            // Always overwrite — files are sorted chronologically,
            // so the last file's rate limits reflect the most recent state.
            if let rateLimits = parsed.rateLimits {
                result.primaryRatePercent = rateLimits.primary?.usedPercent
                result.secondaryRatePercent = rateLimits.secondary?.usedPercent
            }
        }

        return result
    }

    /// Parses a session file into a full SessionDetail (name, project, usage).
    static func parseSessionDetail(at url: URL) -> SessionDetail? {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return nil }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let decoder = JSONDecoder()

        var lastUsage: UsageDetail?
        var lastRateLimits: RateLimits?
        var lastMessageTimestamp: Date?
        var project: String?
        let fileTimestamp = timestampFromFilename(url.lastPathComponent)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for line in lines {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let type = json["type"] as? String else { continue }

            if type == "session_meta",
               let payload = json["payload"] as? [String: Any],
               let cwd = payload["cwd"] as? String {
                project = URL(fileURLWithPath: cwd).lastPathComponent
            }

            // Track timestamp of last user message
            if type == "event_msg",
               let payload = json["payload"] as? [String: Any],
               let pType = payload["type"] as? String,
               pType == "user_message",
               let ts = json["timestamp"] as? String {
                lastMessageTimestamp = isoFormatter.date(from: ts)
            }

            if let ld = line.data(using: .utf8),
               let logLine = try? decoder.decode(LogLine.self, from: ld),
               logLine.type == "event_msg",
               logLine.payload.type == "token_count",
               let info = logLine.payload.info {
                lastUsage = info.totalTokenUsage
                lastRateLimits = logLine.payload.rateLimits
            }
        }

        guard let usage = lastUsage else { return nil }

        var agg = AggregatedUsage.zero
        agg.add(usage)
        if let rl = lastRateLimits {
            agg.primaryRatePercent = rl.primary?.usedPercent
            agg.secondaryRatePercent = rl.secondary?.usedPercent
        }

        let sessionId = extractUUID(from: url.lastPathComponent)
        let displayTime = lastMessageTimestamp ?? fileTimestamp

        return SessionDetail(
            id: sessionId,
            fileURL: url,
            timestamp: displayTime,
            name: displayTime.formatted(date: .omitted, time: .shortened),
            project: project,
            usage: agg
        )
    }

    private static func extractUUID(from filename: String) -> String {
        let name = filename.replacingOccurrences(of: ".jsonl", with: "")
        return name.count >= 36 ? String(name.suffix(36)) : name
    }

    private static func timestampFromFilename(_ filename: String) -> Date {
        let name = filename.replacingOccurrences(of: ".jsonl", with: "")
        guard name.count > 27 else { return Date() }
        let dateStr = String(name.dropFirst("rollout-".count).prefix(19))
            .replacingOccurrences(of: "T", with: " ")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        formatter.timeZone = .current
        return formatter.date(from: dateStr) ?? Date()
    }
}
