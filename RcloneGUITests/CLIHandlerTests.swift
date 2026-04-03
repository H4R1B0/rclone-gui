import Testing
@testable import RcloneGUI

@Suite("CLIHandler Tests")
struct CLIHandlerTests {
    @Test("parseRemotePath — cloud path")
    func cloudPath() {
        let (fs, path) = CLIHandler.parseRemotePath("gdrive:/Documents")
        #expect(fs == "gdrive:")
        #expect(path == "/Documents")
    }

    @Test("parseRemotePath — local path")
    func localPath() {
        let (fs, path) = CLIHandler.parseRemotePath("/Users/test/file.txt")
        #expect(fs == "/")
        #expect(path == "/Users/test/file.txt")
    }

    @Test("parseRemotePath — remote root only")
    func remoteRoot() {
        let (fs, path) = CLIHandler.parseRemotePath("s3:")
        #expect(fs == "s3:")
        #expect(path == "")
    }

    @Test("parseRemotePath — nested cloud path")
    func nestedPath() {
        let (fs, path) = CLIHandler.parseRemotePath("b2:bucket/folder/file.txt")
        #expect(fs == "b2:")
        #expect(path == "bucket/folder/file.txt")
    }
}
