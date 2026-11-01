import SwiftUI

@main
struct MemoSpaceMacApp: App {
    @StateObject private var model = AppModel.makeDefault()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            AppCommands(model: model)
        }

        Settings {
            SettingsView()
                .environmentObject(model)
                .frame(width: 480, height: 320)
        }
    }
}
