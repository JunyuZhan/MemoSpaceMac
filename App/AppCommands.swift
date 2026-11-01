import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var model: AppModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandGroup(after: .toolbar) {
            Button("刷新") {
                Task { await model.refresh() }
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(model.connectionState != .connected)

            Button("上级目录") {
                Task { await model.goUp() }
            }
            .keyboardShortcut(.upArrow, modifiers: .command)
            .disabled(!model.canGoUp)

            Button("后退") {
                Task { await model.goBack() }
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(!model.canGoBack)

            Button("前进") {
                Task { await model.goForward() }
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(!model.canGoForward)

            Button("搜索") {
                model.searchFocusRequest += 1
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("传输中心") {
                model.isShowingTransferCenter = true
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
        }
    }
}
