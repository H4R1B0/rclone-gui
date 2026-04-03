import Testing
@testable import RcloneGUI
import RcloneKit

@Suite("SearchViewModel Tests")
struct SearchViewModelTests {
    @Test("initializeClouds adds colon and local")
    func initializeClouds() {
        let vm = SearchViewModel(client: MockRcloneClient())
        vm.initializeClouds(remotes: ["gdrive", "s3"])
        #expect(vm.selectedClouds.contains("gdrive:"))
        #expect(vm.selectedClouds.contains("s3:"))
        #expect(vm.selectedClouds.contains("/"))
        #expect(vm.selectedClouds.count == 3)
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
}
