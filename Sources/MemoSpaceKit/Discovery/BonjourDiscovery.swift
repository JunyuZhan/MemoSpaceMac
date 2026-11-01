import Foundation

public struct BonjourDiscovery: DeviceDiscovering {
    private let serviceType: String

    public init(serviceType: String = "_smb._tcp.") {
        self.serviceType = serviceType
    }

    public func discover(timeout: TimeInterval) async -> [DiscoveredDevice] {
        await withCheckedContinuation { continuation in
            let collector = BonjourCollector(serviceType: serviceType, timeout: timeout) { devices in
                continuation.resume(returning: devices)
            }
            collector.start()
        }
    }
}

private final class BonjourCollector: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private let serviceType: String
    private let timeout: TimeInterval
    private let completion: ([DiscoveredDevice]) -> Void
    private let browser = NetServiceBrowser()
    private var resolving: Set<NetService> = []
    private var devices: [DiscoveredDevice] = []
    private let lock = NSLock()
    private var finished = false
    private var selfRetain: BonjourCollector?

    init(serviceType: String, timeout: TimeInterval,
         completion: @escaping ([DiscoveredDevice]) -> Void) {
        self.serviceType = serviceType
        self.timeout = timeout
        self.completion = completion
    }

    func start() {
        selfRetain = self
        browser.delegate = self
        browser.searchForServices(ofType: serviceType, inDomain: "local.")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.finish()
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService,
                           moreComing: Bool) {
        lock.lock()
        resolving.insert(service)
        lock.unlock()
        service.delegate = self
        service.resolve(withTimeout: 3)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        lock.lock()
        resolving.remove(sender)
        if let host = sender.hostName {
            devices.append(DiscoveredDevice(name: sender.name, host: host,
                                            port: sender.port, source: .bonjour))
        }
        lock.unlock()
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        lock.lock()
        resolving.remove(sender)
        lock.unlock()
    }

    private func finish() {
        lock.lock()
        if finished {
            lock.unlock()
            return
        }
        finished = true
        let result = devices
        let pending = resolving
        resolving.removeAll()
        lock.unlock()

        browser.stop()
        pending.forEach { $0.stop() }
        completion(result)
        selfRetain = nil
    }
}
