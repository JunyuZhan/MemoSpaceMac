import Foundation
import Network

public struct NetBIOSResolver: DeviceDiscovering {
    private let port: UInt16
    private let broadcastAddress: String

    public init(port: UInt16 = 137, broadcastAddress: String = "255.255.255.255") {
        self.port = port
        self.broadcastAddress = broadcastAddress
    }

    public func discover(timeout: TimeInterval) async -> [DiscoveredDevice] {
        guard let listener = try? NWListener(using: .udp) else { return [] }
        let queue = DispatchQueue(label: "memospace.netbios")
        var devices: [DiscoveredDevice] = []
        let lock = NSLock()

        listener.newConnectionHandler = { connection in
            connection.start(queue: queue)
            connection.receiveMessage { data, _, _, _ in
                guard let data,
                      let remote = connection.currentPath?.remoteEndpoint,
                      case let .hostPort(host, _) = remote
                else {
                    connection.cancel()
                    return
                }
                let names = Self.parseNames(data)
                guard names.contains(where: { $0.uppercased().contains("MEMOSPACE") }) else {
                    connection.cancel()
                    return
                }
                let device = DiscoveredDevice(
                    name: names.first(where: { $0.uppercased().contains("MEMOSPACE") }) ?? "华为家庭存储",
                    host: "\(host)",
                    port: 445,
                    source: .netbios
                )
                lock.lock()
                if !devices.contains(device) { devices.append(device) }
                lock.unlock()
                connection.cancel()
            }
        }

        listener.stateUpdateHandler = { state in
            guard case .ready = state else { return }
            let connection = NWConnection(
                host: NWEndpoint.Host(broadcastAddress),
                port: NWEndpoint.Port(rawValue: port)!,
                using: .udp
            )
            connection.start(queue: queue)
            connection.send(content: Self.makeQuery(transactionID: 0x4D53),
                            completion: .contentProcessed { _ in })
        }

        listener.start(queue: queue)
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        listener.cancel()

        return lock.withLock { devices }
    }

    static func makeQuery(transactionID: UInt16) -> Data {
        var data = Data()
        data.append(contentsOf: [UInt8(transactionID >> 8), UInt8(transactionID & 0xFF)])
        data.append(contentsOf: [0x00, 0x00])
        data.append(contentsOf: [0x00, 0x01])
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

        var name = Array("*".utf8)
        name += Array(repeating: 0x00, count: 16 - name.count)
        data.append(0x20)
        for byte in name {
            data.append(0x41 + (byte >> 4))
            data.append(0x41 + (byte & 0x0F))
        }
        data.append(0x00)
        data.append(contentsOf: [0x00, 0x21, 0x00, 0x01])
        return data
    }

    static func parseNames(_ data: Data) -> [String] {
        guard data.count > 12 else { return [] }
        var offset = 12
        guard let afterQuestion = skipName(data, offset: &offset) else { return [] }
        offset = afterQuestion + 4

        guard offset + 12 <= data.count else { return [] }
        if data[offset] & 0xC0 == 0xC0 {
            offset += 2
        } else if skipName(data, offset: &offset) == nil {
            return []
        }
        offset += 2 + 2 + 4
        guard offset + 2 <= data.count else { return [] }
        let rdLength = Int(data[offset]) << 8 | Int(data[offset + 1])
        offset += 2
        guard offset < data.count, offset + rdLength <= data.count else { return [] }
        let numberOfNames = Int(data[offset])
        offset += 1
        var names: [String] = []
        for _ in 0..<numberOfNames {
            guard offset + 15 <= data.count else { break }
            let raw = data.subdata(in: offset..<(offset + 15))
            let name = String(decoding: raw, as: UTF8.self)
                .trimmingCharacters(in: CharacterSet(charactersIn: " \0"))
            if !name.isEmpty { names.append(name) }
            offset += 18
        }
        return names
    }

    private static func skipName(_ data: Data, offset: inout Int) -> Int? {
        while offset < data.count {
            let length = Int(data[offset])
            if length == 0 {
                offset += 1
                return offset
            }
            if length & 0xC0 == 0xC0 {
                offset += 2
                return offset
            }
            offset += 1 + length
        }
        return nil
    }
}
