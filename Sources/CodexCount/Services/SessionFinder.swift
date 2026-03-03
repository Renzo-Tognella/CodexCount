import Foundation

enum SessionFinder {
    private static let calendar = Calendar.current

    /// Returns all .jsonl session files for a given date.
    static func files(for date: Date, basePath: String) -> [URL] {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return [] }

        let expanded = (basePath as NSString).expandingTildeInPath
        let dirURL = URL(fileURLWithPath: expanded)
            .appendingPathComponent(String(format: "%04d", year))
            .appendingPathComponent(String(format: "%02d", month))
            .appendingPathComponent(String(format: "%02d", day))

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dirURL, includingPropertiesForKeys: nil
        ) else { return [] }

        return contents
            .filter { $0.pathExtension == "jsonl" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Returns all .jsonl files for the current week (Monday → Sunday) up to referenceDate.
    static func weekFiles(referenceDate: Date, basePath: String) -> [URL] {
        let weekday = calendar.component(.weekday, from: referenceDate)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: referenceDate)) else { return [] }

        var allFiles: [URL] = []
        for offset in 0...6 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday),
                  day <= referenceDate else { continue }
            allFiles.append(contentsOf: files(for: day, basePath: basePath))
        }
        return allFiles
    }

    /// Returns the Monday..Sunday date range for the week containing referenceDate.
    static func weekRange(referenceDate: Date) -> (start: Date, end: Date) {
        let weekday = calendar.component(.weekday, from: referenceDate)
        let daysSinceMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: referenceDate))!
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
        return (monday, min(sunday, referenceDate))
    }

    /// Returns all .jsonl files for the current month up to referenceDate.
    static func monthFiles(referenceDate: Date, basePath: String) -> [URL] {
        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        guard let firstOfMonth = calendar.date(from: components) else { return [] }
        return rangeFiles(from: firstOfMonth, to: referenceDate, basePath: basePath)
    }

    /// Returns all .jsonl files between two dates (inclusive).
    static func rangeFiles(from start: Date, to end: Date, basePath: String) -> [URL] {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)

        var allFiles: [URL] = []
        var current = startDay
        while current <= endDay {
            allFiles.append(contentsOf: files(for: current, basePath: basePath))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return allFiles
    }

    /// Validates that the given path looks like a Codex sessions directory.
    static func isValidSessionsPath(_ path: String) -> Bool {
        let expanded = (path as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir) && isDir.boolValue
    }
}
