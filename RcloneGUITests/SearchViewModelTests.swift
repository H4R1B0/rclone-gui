import Foundation
import Testing
@testable import RcloneGUI
import RcloneKit

@Suite("SearchViewModel Tests")
struct SearchViewModelTests {
    @Test("initializeClouds adds colon (cloud only)")
    func initializeClouds() {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.initializeClouds(remotes: ["gdrive", "s3"])
        #expect(vm.selectedClouds.contains("gdrive:"))
        #expect(vm.selectedClouds.contains("s3:"))
        #expect(!vm.selectedClouds.contains("/"))  // 로컬 제외
        #expect(vm.selectedClouds.count == 2)
    }

    @Test("toggleCloud removes if present")
    func toggleCloudRemove() {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.selectedClouds = ["gdrive:", "/"]
        vm.toggleCloud("gdrive:")
        #expect(!vm.selectedClouds.contains("gdrive:"))
    }

    @Test("toggleCloud adds if absent")
    func toggleCloudAdd() {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.selectedClouds = ["/"]
        vm.toggleCloud("s3:")
        #expect(vm.selectedClouds.contains("s3:"))
    }

    @Test("performSearch with empty query does nothing") @MainActor
    func emptyQuery() async {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.query = "   "
        await vm.performSearch()
        #expect(!vm.isSearching)
        #expect(vm.results.isEmpty)
    }

    @Test("abortSearch stops searching")
    func abortSearch() {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.isSearching = true
        vm.abortSearch()
        #expect(!vm.isSearching)
    }

    @Test("performSearch sets hasSearched") @MainActor
    func performSearchSetsFlag() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": []]
        let vm = SearchViewModel(client: mock)
        vm.selectedClouds = ["/"]
        vm.query = "test"
        await vm.performSearch()
        // Wait briefly for task
        try? await Task.sleep(for: .milliseconds(200))
        #expect(vm.hasSearched == true)
    }

    @Test("setSort same field toggles asc")
    func setSortToggles() {
        let vm = SearchViewModel(client: MockRcloneClient())
        #expect(vm.sortField == .name)
        #expect(vm.sortAsc == true)
        vm.setSort(.name)
        #expect(vm.sortAsc == false)
        vm.setSort(.name)
        #expect(vm.sortAsc == true)
    }

    @Test("setSort different field resets to asc")
    func setSortDifferent() {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.sortAsc = false
        vm.setSort(.size)
        #expect(vm.sortField == .size)
        #expect(vm.sortAsc == true)
    }

    @Test("sortedResults orders by size ascending")
    func sortBySize() {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.sortField = .size
        vm.sortAsc = true
        let input = [
            SearchResult(name: "b", path: "b", size: 200, modTime: Date(), isDir: false, mimeType: nil, remoteFs: "/"),
            SearchResult(name: "a", path: "a", size: 100, modTime: Date(), isDir: false, mimeType: nil, remoteFs: "/"),
        ]
        let sorted = vm.sortedResults(input)
        #expect(sorted.first?.size == 100)
        #expect(sorted.last?.size == 200)
    }

    @Test("sortedResults reverses when sortAsc false")
    func sortDescending() {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.sortField = .name
        vm.sortAsc = false
        let input = [
            SearchResult(name: "a", path: "a", size: 10, modTime: Date(), isDir: false, mimeType: nil, remoteFs: "/"),
            SearchResult(name: "b", path: "b", size: 20, modTime: Date(), isDir: false, mimeType: nil, remoteFs: "/"),
        ]
        let sorted = vm.sortedResults(input)
        #expect(sorted.first?.name == "b")
    }

    @Test("performSearch records history") @MainActor
    func recordsHistory() async {
        let mock = MockRcloneClient()
        mock.responses["operations/list"] = ["list": []]
        let store = SearchHistoryStore(defaults: UserDefaults(suiteName: "test-rec-\(UUID().uuidString)")!,
                                        key: "h", maxItems: 10)
        let vm = SearchViewModel(client: mock, history: store)
        vm.selectedClouds = ["/"]
        vm.query = "hello"
        await vm.performSearch()
        #expect(store.recent.first == "hello")
    }
}

@Suite("SearchHistoryStore")
struct SearchHistoryStoreTests {
    private func makeStore(max: Int = 10) -> SearchHistoryStore {
        let d = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        return SearchHistoryStore(defaults: d, key: "h", maxItems: max)
    }

    @Test("record inserts at top")
    func recordTop() {
        let store = makeStore()
        store.record("a")
        store.record("b")
        #expect(store.recent == ["b", "a"])
    }

    @Test("record ignores empty/whitespace")
    func recordEmpty() {
        let store = makeStore()
        store.record("   ")
        store.record("")
        #expect(store.recent.isEmpty)
    }

    @Test("record deduplicates case-insensitive and promotes")
    func recordDedup() {
        let store = makeStore()
        store.record("Hello")
        store.record("world")
        store.record("HELLO")
        #expect(store.recent == ["HELLO", "world"])
    }

    @Test("record caps at maxItems")
    func recordCap() {
        let store = makeStore(max: 3)
        for i in 0..<5 { store.record("q\(i)") }
        #expect(store.recent.count == 3)
        #expect(store.recent == ["q4", "q3", "q2"])
    }

    @Test("remove deletes exact match")
    func removeExact() {
        let store = makeStore()
        store.record("a")
        store.record("b")
        store.remove("a")
        #expect(store.recent == ["b"])
    }

    @Test("clear empties")
    func clear() {
        let store = makeStore()
        store.record("a")
        store.clear()
        #expect(store.recent.isEmpty)
    }

    @Test("persists and loads")
    func persist() {
        let suite = "test-persist-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        let s1 = SearchHistoryStore(defaults: d, key: "k", maxItems: 5)
        s1.record("x")
        s1.record("y")
        let s2 = SearchHistoryStore(defaults: d, key: "k", maxItems: 5)
        #expect(s2.recent == ["y", "x"])
    }
}
