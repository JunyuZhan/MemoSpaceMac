import Foundation

public struct DiscoveredDevice: Identifiable, Hashable, Sendable {
    public enum Source: String, Sendable {
        case bonjour, netbios, manual
    }

    public let id: String
    public let name: String
    public let host: String
    public let port: Int
    public let source: Source

    public init(id: String? = nil, name: String, host: String,
                port: Int = 445, source: Source) {
        self.id = id ?? "\(source.rawValue)-\(host)-\(port)"
        self.name = name
        self.host = host
        self.port = port
        self.source = source
    }
}

public protocol DeviceDiscovering: Sendable {
    func discover(timeout: TimeInterval) async -> [DiscoveredDevice]
}

public struct CompositeDiscovery: DeviceDiscovering {
    private let providers: [any DeviceDiscovering]

    public init(providers: [any DeviceDiscovering] = [BonjourDiscovery(), NetBIOSResolver()]) {
        self.providers = providers
    }

    public func discover(timeout: TimeInterval) async -> [DiscoveredDevice] {
        await withTaskGroup(of: [DiscoveredDevice].self) { group in
            for provider in providers {
                group.addTask { await provider.discover(timeout: timeout) }
            }
            var seen = Set<String>()
            var devices: [DiscoveredDevice] = []
            for await found in group {
                for device in found where seen.insert(device.id).inserted {
                    devices.append(device)
                }
            }
            return devices.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }
}
