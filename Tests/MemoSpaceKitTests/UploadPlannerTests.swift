import Foundation
import Testing
@testable import MemoSpaceKit

@Suite struct UploadPlannerTests {
    private func makeRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    @Test func plansDirectoriesBeforeFiles() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("相册")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("x".utf8).write(to: folder.appendingPathComponent("a.jpg"))
        try Data("y".utf8).write(to: root.appendingPathComponent("b.txt"))

        let plan = try UploadPlanner.plan(for: root)
        let name = root.lastPathComponent
        #expect(plan.filter(\.isDirectory).count == 2)
        #expect(plan.last?.relativePath == "\(name)/相册/a.jpg")

        let folderIndex = try #require(plan.firstIndex { $0.relativePath == "\(name)/相册" })
        let fileIndex = try #require(plan.firstIndex { $0.relativePath == "\(name)/相册/a.jpg" })
        #expect(folderIndex < fileIndex)
    }

    @Test func singleFilePlanUsesFileName() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("a.txt")
        try Data("x".utf8).write(to: file)

        let plan = try UploadPlanner.plan(for: file)
        #expect(plan.count == 1)
        #expect(plan.first?.relativePath == "a.txt")
        #expect(plan.first?.isDirectory == false)
    }

    @Test func missingPathThrows() {
        #expect(throws: SMBError.self) {
            _ = try UploadPlanner.plan(for: URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)"))
        }
    }
}
