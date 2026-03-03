import SwiftUI

@main
struct CodexCountApp: App {
    @StateObject private var vm = TokenViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(vm: vm)
        } label: {
            Label("Codex", systemImage: "number.circle")
        }
        .menuBarExtraStyle(.window)
    }
}
