import Foundation

enum SettingsManager {
    private static let pathKey = "codexSessionsPath"
    private static let visibilityKey = "codexVisibleSections"
    private static let defaultPath = "~/.codex/sessions"

    static var sessionsPath: String {
        get { UserDefaults.standard.string(forKey: pathKey) ?? defaultPath }
        set { UserDefaults.standard.set(newValue, forKey: pathKey) }
    }

    static var isConfigured: Bool {
        UserDefaults.standard.string(forKey: pathKey) != nil
    }

    static var visibleSections: Set<ViewSection> {
        get {
            guard let raw = UserDefaults.standard.array(forKey: visibilityKey) as? [String] else {
                return Set(ViewSection.allCases)
            }
            return Set(raw.compactMap { ViewSection(rawValue: $0) })
        }
        set {
            UserDefaults.standard.set(newValue.map(\.rawValue), forKey: visibilityKey)
        }
    }

    static func toggleSection(_ section: ViewSection) {
        var current = visibleSections
        if current.contains(section) {
            current.remove(section)
        } else {
            current.insert(section)
        }
        visibleSections = current
    }
}
