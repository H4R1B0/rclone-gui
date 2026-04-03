import Testing
@testable import RcloneGUI

@Suite("DuplicateGroup Tests")
struct DuplicateGroupTests {
    @Test("Wasted space calculation")
    func wastedSpace() {
        let group = DuplicateGroup(hash: "abc123", size: 1024, files: [
            (remote: "gdrive:", path: "/a.txt", name: "a.txt"),
            (remote: "s3:", path: "/a.txt", name: "a.txt"),
            (remote: "/", path: "/a.txt", name: "a.txt"),
        ])
        #expect(group.count == 3)
        #expect(group.wastedSpace == 1024 * 2)  // (count-1) * size
    }

    @Test("Single file = no waste")
    func singleFile() {
        let group = DuplicateGroup(hash: "xyz", size: 500, files: [
            (remote: "/", path: "/file.txt", name: "file.txt"),
        ])
        #expect(group.wastedSpace == 0)
    }

    @Test("Empty files")
    func emptyFiles() {
        let group = DuplicateGroup(hash: "000", size: 0, files: [
            (remote: "/", path: "/a", name: "a"),
            (remote: "/", path: "/b", name: "b"),
        ])
        #expect(group.wastedSpace == 0)
    }

    @Test("Total wasted across groups")
    func totalWasted() {
        let detector = DuplicateDetector(client: MockRcloneClient())
        detector.groups = [
            DuplicateGroup(hash: "a", size: 100, files: [
                (remote: "/", path: "/1", name: "1"),
                (remote: "/", path: "/2", name: "2"),
            ]),
            DuplicateGroup(hash: "b", size: 200, files: [
                (remote: "/", path: "/3", name: "3"),
                (remote: "/", path: "/4", name: "4"),
                (remote: "/", path: "/5", name: "5"),
            ]),
        ]
        #expect(detector.totalWasted == 100 + 400)  // 100*1 + 200*2
    }
}
