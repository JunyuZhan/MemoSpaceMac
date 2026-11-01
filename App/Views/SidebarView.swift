import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        List {
            if let profile = model.profile {
                Section("设备") {
                    Label(profile.displayName, systemImage: "externaldrive.connected.to.line.below")
                    Text(profile.host).font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("共享") {
                ForEach(model.shares, id: \.self) { share in
                    Button {
                        Task { await model.selectShare(share) }
                    } label: {
                        Label(share, systemImage: share == model.profile?.lastShare
                              ? "folder.fill" : "folder")
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                Button {
                    model.isShowingTransferCenter = true
                } label: {
                    Label("传输中心", systemImage: "arrow.up.arrow.down")
                }
                .buttonStyle(.plain)

                Button {
                    Task { await model.disconnect() }
                } label: {
                    Label("断开连接", systemImage: "wifi.slash")
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
    }
}
