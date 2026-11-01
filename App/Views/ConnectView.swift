import SwiftUI
import MemoSpaceKit

struct ConnectView: View {
    @EnvironmentObject private var model: AppModel

    @State private var host = ""
    @State private var port = "445"
    @State private var username = ""
    @State private var password = ""
    @State private var share = "家庭共享"
    @State private var isGuest = true
    @State private var rememberPassword = true
    @State private var selectedProfileID: UUID?
    @State private var savedProfiles: [ConnectionProfile] = []

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            form
        }
        .task {
            savedProfiles = model.loadSavedProfiles()
            if let profile = savedProfiles.first {
                apply(profile)
            }
            await model.startDiscovery()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设备").font(.headline)
            if model.isDiscovering {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("正在搜索…").foregroundStyle(.secondary)
                }
            }
            List(model.devices) { device in
                Button {
                    host = device.host
                    port = String(device.port)
                    selectedProfileID = nil
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name)
                        Text("\(device.host):\(device.port)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(minHeight: 120)

            Divider()
            Text("已保存").font(.headline)
            List(savedProfiles) { profile in
                Button {
                    apply(profile)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.displayName)
                        Text(profile.host).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()
            Button {
                Task { await model.startDiscovery() }
            } label: {
                Label("重新搜索", systemImage: "arrow.clockwise")
            }
        }
        .padding()
        .frame(width: 260)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("连接华为家庭存储").font(.title2).bold()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("地址").gridColumnAlignment(.trailing)
                    TextField("192.168.1.10", text: $host)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                    Text("端口").gridColumnAlignment(.trailing)
                    TextField("445", text: $port)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                GridRow {
                    Text("共享名").gridColumnAlignment(.trailing)
                    TextField("家庭共享", text: $share)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }
                GridRow {
                    Text("用户名").gridColumnAlignment(.trailing)
                    TextField("guest", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                        .disabled(isGuest)
                }
                GridRow {
                    Text("密码").gridColumnAlignment(.trailing)
                    SecureField("密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                        .disabled(isGuest)
                }
            }

            Toggle("游客登录", isOn: $isGuest)
            Toggle("记住密码", isOn: $rememberPassword)

            if case let .failed(message) = model.connectionState {
                Text(message).foregroundStyle(.red).font(.callout)
            }

            HStack {
                Button {
                    connect()
                } label: {
                    if model.connectionState == .connecting {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("连接")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(host.isEmpty || model.connectionState == .connecting)
            }

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 520, alignment: .leading)
    }

    private func apply(_ profile: ConnectionProfile) {
        selectedProfileID = profile.id
        host = profile.host
        port = String(profile.port)
        username = profile.username
        isGuest = profile.isGuest
        share = profile.lastShare ?? profile.knownShares.first ?? "家庭共享"
        password = model.password(for: profile) ?? ""
    }

    private func connect() {
        let profile = ConnectionProfile(
            id: selectedProfileID ?? UUID(),
            host: host,
            port: Int(port) ?? 445,
            username: isGuest ? "guest" : username,
            isGuest: isGuest,
            knownShares: [share],
            lastShare: share
        )
        Task {
            await model.connect(profile: profile, password: isGuest ? "" : password,
                                share: share, rememberPassword: rememberPassword)
        }
    }
}
