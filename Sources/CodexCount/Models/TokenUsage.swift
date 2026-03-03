import Foundation

// MARK: - JSONL Line Parsing

struct LogLine: Decodable {
    let timestamp: String
    let type: String
    let payload: LogPayload
}

struct LogPayload: Decodable {
    let type: String
    let info: TokenInfo?
    let rateLimits: RateLimits?

    enum CodingKeys: String, CodingKey {
        case type, info
        case rateLimits = "rate_limits"
    }
}

struct TokenInfo: Decodable {
    let totalTokenUsage: UsageDetail
    let lastTokenUsage: UsageDetail

    enum CodingKeys: String, CodingKey {
        case totalTokenUsage = "total_token_usage"
        case lastTokenUsage = "last_token_usage"
    }
}

// MARK: - Usage Detail

struct UsageDetail: Decodable {
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningOutputTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case cachedInputTokens = "cached_input_tokens"
        case outputTokens = "output_tokens"
        case reasoningOutputTokens = "reasoning_output_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Rate Limits

struct RateLimits: Decodable {
    let primary: RateWindow?
    let secondary: RateWindow?
}

struct RateWindow: Decodable {
    let usedPercent: Double
    let windowMinutes: Int
    let resetsAt: Int

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case windowMinutes = "window_minutes"
        case resetsAt = "resets_at"
    }
}

// MARK: - Aggregated Result

struct AggregatedUsage {
    var newInputTokens: Int = 0
    var cachedInputTokens: Int = 0
    var outputTokens: Int = 0
    var reasoningOutputTokens: Int = 0
    var totalTokens: Int = 0
    var primaryRatePercent: Double? = nil
    var secondaryRatePercent: Double? = nil

    static let zero = AggregatedUsage()

    mutating func add(_ usage: UsageDetail) {
        newInputTokens += usage.inputTokens - usage.cachedInputTokens
        cachedInputTokens += usage.cachedInputTokens
        outputTokens += usage.outputTokens
        reasoningOutputTokens += usage.reasoningOutputTokens
        totalTokens += usage.totalTokens
    }
}

// MARK: - Session Detail

struct SessionDetail: Identifiable {
    let id: String
    let fileURL: URL
    let timestamp: Date
    let name: String
    let project: String?
    let usage: AggregatedUsage
}

// MARK: - View Section Visibility

enum ViewSection: String, CaseIterable, Identifiable {
    case daily = "Diário"
    case weekly = "Semanal"
    case monthly = "Mensal"
    case custom = "Período personalizado"
    case sessions = "Por sessão"
    case rateLimits = "Rate Limits"

    var id: String { rawValue }
}
