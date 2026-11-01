import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct NetBIOSTests {
    private func makeResponse(names: [String]) -> Data {
        var data = Data(repeating: 0, count: 12)
        data[4] = 0; data[5] = 1
        data[6] = 0; data[7] = 1

        var qname = Array("*".utf8)
        qname += Array(repeating: 0x00, count: 16 - qname.count)
        data.append(0x20)
        for byte in qname {
            data.append(0x41 + (byte >> 4))
            data.append(0x41 + (byte & 0x0F))
        }
        data.append(0x00)
        data.append(contentsOf: [0x00, 0x21, 0x00, 0x01])

        data.append(contentsOf: [0xC0, 0x0C])
        data.append(contentsOf: [0x00, 0x21, 0x00, 0x01])
        data.append(contentsOf: [0, 0, 0, 0])
        let rdLength = 1 + names.count * 18
        data.append(contentsOf: [UInt8(rdLength >> 8), UInt8(rdLength & 0xFF)])
        data.append(UInt8(names.count))
        for name in names {
            var bytes = Array(name.uppercased().utf8.prefix(15))
            bytes += Array(repeating: 0x20, count: 15 - bytes.count)
            data.append(contentsOf: bytes)
            data.append(0x00)
            data.append(contentsOf: [0x00, 0x00])
        }
        return data
    }

    @Test func parsesNBSTATNames() {
        let packet = makeResponse(names: ["MEMOSPACE", "WORKGROUP"])
        #expect(NetBIOSResolver.parseNames(packet) == ["MEMOSPACE", "WORKGROUP"])
    }

    @Test func rejectsShortPacket() {
        #expect(NetBIOSResolver.parseNames(Data([1, 2, 3])) == [])
    }

    @Test func queryPacketHasNBSTATType() {
        let query = NetBIOSResolver.makeQuery(transactionID: 0x4D53)
        #expect(query.count == 50)
        #expect(Array(query.suffix(4)) == [0x00, 0x21, 0x00, 0x01])
    }

    @Test func discoveredDeviceIdentity() {
        let device = DiscoveredDevice(name: "MEMOSPACE", host: "192.168.1.5", source: .netbios)
        #expect(device.id == "netbios-192.168.1.5-445")
    }
}
