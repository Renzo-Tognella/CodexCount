import Foundation
import SwiftUI

@MainActor
final class TokenViewModel: ObservableObject {
    @Published var todayUsage = AggregatedUsage.zero
    @Published var weekUsage = AggregatedUsage.zero
    @Published var monthUsage = AggregatedUsage.zero
    @Published var customUsage = AggregatedUsage.zero
    @Published var latestRateLimits = AggregatedUsage.zero
    @Published var sessions: [SessionDetail] = []
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var showSettings: Bool

    private var refreshTimer: Timer?

    @Published var customStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @Published var customEnd = Date()

    @Published var todayLabel = ""
    @Published var weekLabel = ""
    @Published var monthLabel = ""

    @Published var visibleSections = SettingsManager.visibleSections

    init() {
        showSettings = !SettingsManager.isConfigured
        if SettingsManager.isConfigured { refresh() }
        startAutoRefresh()
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    func refresh() {
        isLoading = true
        let path = SettingsManager.sessionsPath
        let today = Date()
        let rangeStart = customStart
        let rangeEnd = customEnd

        Task.detached(priority: .userInitiated) {
            let todayFiles = SessionFinder.files(for: today, basePath: path)
            let todayResult = LogParser.aggregate(sessionFiles: todayFiles)
            let todayStr = today.formatted(date: .abbreviated, time: .omitted)

            let weekFiles = SessionFinder.weekFiles(referenceDate: today, basePath: path)
            let weekResult = LogParser.aggregate(sessionFiles: weekFiles)
            let wr = SessionFinder.weekRange(referenceDate: today)
            let weekStr = "\(wr.start.formatted(date: .abbreviated, time: .omitted)) – \(wr.end.formatted(date: .abbreviated, time: .omitted))"

            let monthFiles = SessionFinder.monthFiles(referenceDate: today, basePath: path)
            let monthResult = LogParser.aggregate(sessionFiles: monthFiles)
            let mf = DateFormatter()
            mf.dateFormat = "MMMM yyyy"
            let monthStr = mf.string(from: today)

            let rangeFiles = SessionFinder.rangeFiles(from: rangeStart, to: rangeEnd, basePath: path)
            let customResult = LogParser.aggregate(sessionFiles: rangeFiles)

            let sessionDetails = todayFiles.compactMap { LogParser.parseSessionDetail(at: $0) }
                .sorted { $0.timestamp > $1.timestamp }

            // Rate limits: use the most recent session across all today's files
            let latestRL = sessionDetails.first?.usage ?? todayResult

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.todayUsage = todayResult
                self.weekUsage = weekResult
                self.monthUsage = monthResult
                self.customUsage = customResult
                self.latestRateLimits = latestRL
                self.sessions = sessionDetails
                self.todayLabel = todayStr
                self.weekLabel = weekStr
                self.monthLabel = monthStr
                self.lastUpdated = Date()
                self.isLoading = false
            }
        }
    }

    func savePath(_ path: String) {
        SettingsManager.sessionsPath = path
        showSettings = false
        refresh()
    }

    func toggleSection(_ section: ViewSection) {
        SettingsManager.toggleSection(section)
        visibleSections = SettingsManager.visibleSections
    }

    func isVisible(_ section: ViewSection) -> Bool {
        visibleSections.contains(section)
    }
}
