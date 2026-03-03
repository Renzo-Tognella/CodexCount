import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var vm: TokenViewModel
    @State private var path: String = SettingsManager.sessionsPath
    @State private var isValid = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Path config
            VStack(alignment: .leading, spacing: 8) {
                Text("Caminho das sessions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    TextField("~/.codex/sessions", text: $path)
                        .textFieldStyle(.roundedBorder)
                        .font(.callout.monospaced())
                        .onChange(of: path) { _ in isValid = true }

                    Button("Selecionar") { pickFolder() }
                        .controlSize(.small)
                }

                if !isValid {
                    Text("Caminho inválido. Selecione uma pasta existente.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Divider()

            // Visibility toggles
            VStack(alignment: .leading, spacing: 8) {
                Text("Seções visíveis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(ViewSection.allCases) { section in
                    Toggle(section.rawValue, isOn: Binding(
                        get: { vm.isVisible(section) },
                        set: { _ in vm.toggleSection(section) }
                    ))
                    .font(.callout)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                }
            }

            Divider()

            HStack {
                Spacer()
                if SettingsManager.isConfigured {
                    Button("Cancelar") { vm.showSettings = false }
                }
                Button("Salvar") { save() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(16)
    }

    private func save() {
        guard SessionFinder.isValidSessionsPath(path) else {
            isValid = false
            return
        }
        vm.savePath(path)
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Selecione a pasta 'sessions' do Codex"

        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
        }
    }
}
