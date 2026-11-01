import Foundation
import Testing
@testable import MemoSpaceKit

@Suite @MainActor struct TransferTaskTests {
    @Test func stateMachine() {
        let task = TransferTask(direction: .download, displayName: "a", remotePath: "/a",
                                localURL: nil, totalBytes: 100)
        #expect(task.state == .queued)
        #expect(task.progress == 0)

        task.start()
        #expect(task.state == .running)
        task.update(transferredBytes: 40)
        #expect(abs(task.progress - 0.4) < 0.0001)
        task.complete()
        #expect(task.state == .completed)
        #expect(abs(task.progress - 0.4) < 0.0001)
    }

    @Test func failureAndCancel() {
        let failed = TransferTask(direction: .upload, displayName: "b", remotePath: "/b",
                                  localURL: nil, totalBytes: 10)
        failed.start()
        failed.fail("磁盘已满")
        #expect(failed.state == .failed("磁盘已满"))

        let cancelled = TransferTask(direction: .upload, displayName: "c", remotePath: "/c",
                                     localURL: nil, totalBytes: 10)
        cancelled.start()
        cancelled.cancel()
        #expect(cancelled.state == .cancelled)
    }

    @Test func resetForRetry() {
        let task = TransferTask(direction: .download, displayName: "a", remotePath: "/a",
                                localURL: nil, totalBytes: 10)
        task.start()
        task.update(transferredBytes: 5)
        task.fail("超时")
        task.reset()
        #expect(task.state == .queued)
        #expect(task.transferredBytes == 0)
    }

    @Test func progressIsClampedAndSafeWithZeroTotal() {
        let task = TransferTask(direction: .download, displayName: "a", remotePath: "/a",
                                localURL: nil, totalBytes: 0)
        #expect(task.progress == 0)
        task.update(transferredBytes: 5)
        #expect(task.progress == 0)

        let other = TransferTask(direction: .download, displayName: "b", remotePath: "/b",
                                 localURL: nil, totalBytes: 10)
        other.update(transferredBytes: 20)
        #expect(other.progress == 1)
    }
}
