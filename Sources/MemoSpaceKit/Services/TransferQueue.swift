import Combine
import Foundation

@MainActor
public final class TransferQueue: ObservableObject {
    public typealias Operation = @MainActor (TransferTask, CancellationFlag) async throws -> Void

    @Published public private(set) var tasks: [TransferTask] = []
    private var operations: [UUID: Operation] = [:]
    private var pending: [UUID] = []
    private var running: Set<UUID> = []
    private var flags: [UUID: CancellationFlag] = [:]
    private let limit: Int

    public init(limit: Int = 2) {
        self.limit = limit
    }

    public var activeCount: Int { running.count }

    public var overallProgress: Double {
        let active = tasks.filter { $0.state == .running || $0.state == .queued }
        guard !active.isEmpty else { return 0 }
        return active.map(\.progress).reduce(0, +) / Double(active.count)
    }

    @discardableResult
    public func enqueue(_ task: TransferTask, operation: @escaping Operation) -> UUID {
        tasks.append(task)
        operations[task.id] = operation
        pending.append(task.id)
        pump()
        return task.id
    }

    public func cancel(id: UUID) {
        if pending.contains(id) {
            pending.removeAll { $0 == id }
            tasks.first { $0.id == id }?.cancel()
        } else {
            flags[id]?.cancel()
        }
    }

    public func retry(id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }), task.state.isFailed else { return }
        task.reset()
        pending.append(id)
        pump()
    }

    public func removeFinished() {
        tasks.removeAll { $0.state.isFinished }
    }

    private func pump() {
        while running.count < limit, !pending.isEmpty {
            let id = pending.removeFirst()
            guard let task = tasks.first(where: { $0.id == id }), task.state == .queued else { continue }
            let flag = CancellationFlag()
            flags[id] = flag
            running.insert(id)
            task.start()
            let operation = operations[id]

            Task { @MainActor [weak self] in
                guard let self else { return }
                defer {
                    self.running.remove(id)
                    self.flags[id] = nil
                    self.pump()
                }
                guard let operation else {
                    task.fail("缺少传输任务")
                    return
                }
                do {
                    try await operation(task, flag)
                    if flag.isCancelled {
                        task.cancel()
                    } else {
                        task.complete()
                    }
                } catch {
                    let mapped = SMBError.map(error)
                    if flag.isCancelled || mapped == .cancelled {
                        task.cancel()
                    } else {
                        task.fail(mapped.localizedDescription)
                    }
                }
            }
        }
    }
}
