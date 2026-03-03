import Foundation

enum TokenFormatter {
    static func format(_ value: Int) -> String {
        switch value {
        case ..<1_000:
            return "\(value)"
        case 1_000..<1_000_000:
            let k = Double(value) / 1_000
            return k >= 100 ? String(format: "%.0fK", k) : String(format: "%.1fK", k)
        default:
            let m = Double(value) / 1_000_000
            return m >= 100 ? String(format: "%.0fM", m) : String(format: "%.1fM", m)
        }
    }
}
