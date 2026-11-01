import Foundation
import Testing
@testable import MemoSpaceKit

@Suite @MainActor struct TransferQueueTests {
    private func waitUntilFinished(_ task: TransferTask) async {
        for _ in 0..<2000 {
            if task.state.isFinished { return }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    @Test func completesTasksAndUpdatesProgress() async {
        let queue = TransferQueue(limit: 2)
        let task = TransferTask(direction: .download, displayName: "a", remotePath: "/a",
                                localURL: nil, totalBytes: 10)
        queue.enqueue(task) { t, _ in
            t.update(transferredBytes: 10)
        }
        await waitUntilFinished(task)
        #expect(task.state == .completed)
        #expect(task.transferredBytes == 10)
    }

    @Test func failureStoresMessageAndRetryResets() async {
        let queue = TransferQueue(limit: 1)
        let task = TransferTask(direction: .upload, displayName: "b", remotePath: "/b",
                                localURL: nil, totalBytes: 10)
        var attempts = 0
        queue.enqueue(task) { _, _ in
            attempts += 1
            if attempts == 1 { throw SMBError.noSpace }
        }
        await waitUntilFinished(task)
        #expect(task.state.isFailed)

        queue.retry(id: task.id)
        await waitUntilFinished(task)
        #expect(task.state == .completed)
        #expect(attempts == 2)
    }

    @Test func cancellationStopsRunningTask() async {
        let queue = TransferQueue(limit: 1)
        let task = TransferTask(direction: .download, displayName: "c", remotePath: "/c",
                                localURL: nil, totalBytes: 10)
        queue.enqueue(task) { _, _ in
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        while task.state == .queued {
            await Task.yield()
        }
        queue.cancel(id: task.id)
        await waitUntilFinished(task)
        #expect(task.state == .cancelled)
    }

    @Test func respectsConcurrencyLimit() async {
        let queue = TransferQueue(limit: 1)
        let first = TransferTask(direction: .download, displayName: "a", remotePath: "/a",
                                 localURL: nil, totalBytes: 10)
        let second = TransferTask(direction: .download, displayName: "b", remotePath: "/b",
                                  localURL: nil, totalBytes: 10)
        var active = 0
        var maxActive = 0
        let operation: TransferQueue.Operation = { _, _ in
            active += 1
            maxActive = max(maxActive, active)
            try? await Task.sleep(nanoseconds: 30_000_000)
            active -= 1
        }
        queue.enqueue(first, operation: operation)
        queue.enqueue(second, operation: operation)
        await waitUntilFinished(first)
        await waitUntilFinished(second)
        #expect(maxActive == 1)
        #expect(first.state == .completed)
        #expect(second.state == .completed)
    }
}
