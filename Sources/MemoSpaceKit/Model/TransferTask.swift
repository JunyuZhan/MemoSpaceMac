import Combine
import Foundation

public final class CancellationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    public init() {}

    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    public func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }
}

@MainActor
public final class TransferTask: ObservableObject, Identifiable {
    public enum Direction: String, Sendable {
        case upload, download
    }

    public enum State: Equatable, Sendable {
        case queued, running, completed, cancelled
        case failed(String)

        public var isFinished: Bool {
            switch self {
            case .completed, .cancelled, .failed: return true
            case .queued, .running: return false
            }
        }

        public var isFailed: Bool {
            if case .failed = self { return true }
            return false
        }
    }

    public let id = UUID()
    public let direction: Direction
    public let displayName: String
    public let remotePath: String
    public let localURL: URL?
    public let totalBytes: Int64

    @Published public private(set) var transferredBytes: Int64 = 0
    @Published public private(set) var state: State = .queued

    public init(direction: Direction, displayName: String, remotePath: String,
                localURL: URL?, totalBytes: Int64) {
        self.direction = direction
        self.displayName = displayName
        self.remotePath = remotePath
        self.localURL = localURL
        self.totalBytes = totalBytes
    }

    public var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(transferredBytes) / Double(totalBytes), 0), 1)
    }

    public func start() {
        guard state == .queued else { return }
        state = .running
    }

    public func update(transferredBytes: Int64) {
        self.transferredBytes = max(0, transferredBytes)
    }

    public func complete() {
        guard state == .running || state == .queued else { return }
        state = .completed
    }

    public func fail(_ message: String) {
        state = .failed(message)
    }

    public func cancel() {
        state = .cancelled
    }

    public func reset() {
        transferredBytes = 0
        state = .queued
    }
}
