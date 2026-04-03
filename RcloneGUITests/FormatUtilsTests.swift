import Testing
@testable import RcloneGUI

@Suite("FormatUtils Tests")
struct FormatUtilsTests {
    @Test("formatBytes — zero")
    func formatBytesZero() { #expect(FormatUtils.formatBytes(0) == "0 B") }

    @Test("formatBytes — bytes")
    func formatBytesSmall() { #expect(FormatUtils.formatBytes(500) == "500 B") }

    @Test("formatBytes — KB")
    func formatBytesKB() { #expect(FormatUtils.formatBytes(1536).contains("KB")) }

    @Test("formatBytes — MB")
    func formatBytesMB() {
        let result = FormatUtils.formatBytes(1_572_864)
        #expect(result.contains("MB"))
    }

    @Test("formatBytes — GB")
    func formatBytesGB() {
        let result = FormatUtils.formatBytes(1_073_741_824)
        #expect(result.contains("GB"))
    }

    @Test("formatSpeed")
    func formatSpeed() {
        let result = FormatUtils.formatSpeed(1_048_576)
        #expect(result.contains("/s"))
        #expect(result.contains("MB"))
    }

    @Test("formatEta — seconds")
    func formatEtaSeconds() { #expect(FormatUtils.formatEta(45) == "45s") }

    @Test("formatEta — minutes")
    func formatEtaMinutes() {
        let result = FormatUtils.formatEta(150)
        #expect(result.contains("m"))
    }

    @Test("formatEta — hours")
    func formatEtaHours() {
        let result = FormatUtils.formatEta(7200)
        #expect(result.contains("h"))
    }

    @Test("formatEta — zero returns dash")
    func formatEtaZero() { #expect(FormatUtils.formatEta(0) == "-") }

    @Test("fileIcon — folder")
    func fileIconFolder() { #expect(FormatUtils.fileIcon(name: "docs", isDir: true) == "folder.fill") }

    @Test("fileIcon — image")
    func fileIconImage() { #expect(FormatUtils.fileIcon(name: "photo.jpg", isDir: false) == "photo") }

    @Test("fileIcon — video")
    func fileIconVideo() { #expect(FormatUtils.fileIcon(name: "movie.mp4", isDir: false) == "film") }

    @Test("fileIcon — audio")
    func fileIconAudio() { #expect(FormatUtils.fileIcon(name: "song.mp3", isDir: false) == "music.note") }

    @Test("fileIcon — archive")
    func fileIconArchive() { #expect(FormatUtils.fileIcon(name: "backup.zip", isDir: false) == "doc.zipper") }

    @Test("fileIcon — code")
    func fileIconCode() { #expect(FormatUtils.fileIcon(name: "main.swift", isDir: false) == "chevron.left.forwardslash.chevron.right") }

    @Test("fileIcon — default")
    func fileIconDefault() { #expect(FormatUtils.fileIcon(name: "unknown.xyz", isDir: false) == "doc") }
}
