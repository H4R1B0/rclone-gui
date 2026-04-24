import Foundation

/// 최근 검색 쿼리 저장소 (UserDefaults 기반).
/// 최대 AppConstants.maxSearchHistory 항목, 중복 입력 시 최상단 승격.
@Observable
final class SearchHistoryStore {
    private(set) var recent: [String] = []

    private let defaults: UserDefaults
    private let key: String
    private let maxItems: Int

    init(defaults: UserDefaults = .standard,
         key: String = AppConstants.searchHistoryKey,
         maxItems: Int = AppConstants.maxSearchHistory) {
        self.defaults = defaults
        self.key = key
        self.maxItems = maxItems
        load()
    }

    func record(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recent.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recent.insert(trimmed, at: 0)
        if recent.count > maxItems {
            recent = Array(recent.prefix(maxItems))
        }
        save()
    }

    func remove(_ query: String) {
        recent.removeAll { $0 == query }
        save()
    }

    func clear() {
        recent.removeAll()
        save()
    }

    private func load() {
        recent = defaults.stringArray(forKey: key) ?? []
    }

    private func save() {
        defaults.set(recent, forKey: key)
    }
}
