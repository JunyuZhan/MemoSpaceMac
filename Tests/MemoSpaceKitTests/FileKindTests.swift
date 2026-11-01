import Testing
@testable import MemoSpaceKit

@Suite struct FileKindTests {
    @Test func directoriesAreFolders() {
        #expect(FileTypeClassifier.kind(for: "照片.JPG", isDirectory: true) == .folder)
    }

    @Test func extensionMatchingIsCaseInsensitive() {
        #expect(FileTypeClassifier.kind(for: "A.JPEG", isDirectory: false) == .image)
        #expect(FileTypeClassifier.kind(for: "movie.MP4", isDirectory: false) == .video)
        #expect(FileTypeClassifier.kind(for: "song.FLAC", isDirectory: false) == .audio)
        #expect(FileTypeClassifier.kind(for: "doc.PDF", isDirectory: false) == .pdf)
        #expect(FileTypeClassifier.kind(for: "notes.MD", isDirectory: false) == .text)
        #expect(FileTypeClassifier.kind(for: "backup.tar.GZ", isDirectory: false) == .archive)
    }

    @Test func hiddenFilesWithoutExtensionAreOther() {
        #expect(FileTypeClassifier.kind(for: ".DS_Store", isDirectory: false) == .other)
        #expect(FileTypeClassifier.kind(for: ".gitignore", isDirectory: false) == .other)
    }

    @Test func unknownExtensionIsOther() {
        #expect(FileTypeClassifier.kind(for: "data.bin", isDirectory: false) == .other)
        #expect(FileTypeClassifier.kind(for: "README", isDirectory: false) == .other)
    }
}
