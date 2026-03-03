import SwiftUI

struct ContentView: View {
    @ObservedObject var vm: TokenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            if vm.showSettings {
                SettingsView(vm: vm)
            } else if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if vm.isVisible(.daily) {
                            usageSection(title: "Hoje", subtitle: vm.todayLabel, usage: vm.todayUsage)
                            Divider()
                        }
                        if vm.isVisible(.weekly) {
                            usageSection(title: "Semana", subtitle: vm.weekLabel, usage: vm.weekUsage)
                            Divider()
                        }
                        if vm.isVisible(.monthly) {
                            usageSection(title: "Mês", subtitle: vm.monthLabel, usage: vm.monthUsage)
                            Divider()
                        }
                        if vm.isVisible(.custom) {
                            customRangeSection
                            Divider()
                        }
                        if vm.isVisible(.sessions) {
                            sessionsSection
                            Divider()
                        }
                        if vm.isVisible(.rateLimits) {
                            rateLimitsSection
                        }
                        footer
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 320)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Codex Tokens")
                .font(.headline)
            Spacer()
            Button(action: vm.refresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(vm.isLoading)
            Button(action: { vm.showSettings.toggle() }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
    }

    // MARK: - Usage Section

    private func usageSection(title: String, subtitle: String?, usage: AggregatedUsage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            tokenRow("Input (novo)", value: usage.newInputTokens, color: .blue)
            tokenRow("Input (cached)", value: usage.cachedInputTokens, color: .cyan)
            tokenRow("Output", value: usage.outputTokens, color: .green)
            tokenRow("  ↳ Reasoning", value: usage.reasoningOutputTokens, color: Color.green.opacity(0.6))

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(TokenFormatter.format(usage.totalTokens))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        }
    }

    private func tokenRow(_ label: String, value: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.callout)
            Spacer()
            Text(TokenFormatter.format(value))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Custom Range

    private var customRangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Período personalizado")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                DatePicker("", selection: $vm.customStart, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
                Text("–")
                DatePicker("", selection: $vm.customEnd, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
                Button(action: vm.refresh) {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }

            tokenRow("Input (novo)", value: vm.customUsage.newInputTokens, color: .blue)
            tokenRow("Input (cached)", value: vm.customUsage.cachedInputTokens, color: .cyan)
            tokenRow("Output", value: vm.customUsage.outputTokens, color: .green)
            tokenRow("  ↳ Reasoning", value: vm.customUsage.reasoningOutputTokens, color: Color.green.opacity(0.6))

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(TokenFormatter.format(vm.customUsage.totalTokens))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Sessions

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sessões de hoje")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if vm.sessions.isEmpty {
                Text("Nenhuma sessão hoje")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(vm.sessions) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: SessionDetail) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(session.name)
                    .font(.callout.monospacedDigit())
                if let project = session.project {
                    Text(project)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(3)
                }
                Spacer()
                Text(TokenFormatter.format(session.usage.totalTokens))
                    .font(.callout.monospacedDigit().weight(.medium))
            }
            Divider()
        }
    }

    // MARK: - Rate Limits

    private var rateLimitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rate Limits")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let primary = vm.latestRateLimits.primaryRatePercent {
                rateBar(label: "5h window", percent: primary)
            }
            if let secondary = vm.latestRateLimits.secondaryRatePercent {
                rateBar(label: "7d window", percent: secondary)
            }

            if vm.latestRateLimits.primaryRatePercent == nil && vm.latestRateLimits.secondaryRatePercent == nil {
                Text("Sem dados")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func rateBar(label: String, percent: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text(String(format: "%.0f%%", percent))
                    .font(.caption.monospacedDigit())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(percent > 80 ? Color.red : Color.accentColor)
                        .frame(width: geo.size.width * min(percent / 100, 1))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Group {
            if let date = vm.lastUpdated {
                Text("Atualizado: \(date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
