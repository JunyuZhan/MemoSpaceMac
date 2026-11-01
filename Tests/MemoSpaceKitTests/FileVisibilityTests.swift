import Testing
@testable import MemoSpaceKit

@Suite struct FileVisibilityTests {
    @Test func dotFilesAreHidden() {
        #expect(FileVisibility.isSystemHidden(".DS_Store"))
        #expect(FileVisibility.isSystemHidden(".env"))
        #expect(FileVisibility.isSystemHidden(".gitignore"))
    }

    @Test func windowsSystemFilesAreHiddenCaseInsensitively() {
        #expect(FileVisibility.isSystemHidden("Thumbs.db"))
        #expect(FileVisibility.isSystemHidden("thumbs.DB"))
        #expect(FileVisibility.isSystemHidden("desktop.ini"))
    }

    @Test func regularFilesAreVisible() {
        #expect(!FileVisibility.isSystemHidden("IMG_0001.jpg"))
        #expect(!FileVisibility.isSystemHidden("照片"))
        #expect(!FileVisibility.isSystemHidden("thumbs.db.txt"))
    }
}
