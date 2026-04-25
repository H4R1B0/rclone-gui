import Foundation

/// 리모트 표시용 별칭 저장소 (UserDefaults 기반).
/// rclone config 이름은 변경하지 않고, UI에 별도 표시 이름을 부여한다.
@Observable
final class RemoteAliasStore {
    private(set) var aliases: [String: String] = [:]

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard,
         key: String = AppConstants.remoteAliasesKey) {
        self.defaults = defaults
        self.key = key
        load()
    }

    func alias(for remoteName: String) -> String? {
        let value = aliases[remoteName]?.trimmingCharacters(in: .whitespaces)
        return (value?.isEmpty == false) ? value : nil
    }

    func setAlias(name: String, alias: String?) {
        let trimmed = alias?.trimmingCharacters(in: .whitespaces)
        if let t = trimmed, !t.isEmpty {
            aliases[name] = t
        } else {
            aliases.removeValue(forKey: name)
        }
        save()
    }

    func removeAll() {
        aliases.removeAll()
        save()
    }

    private func load() {
        aliases = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    private func save() {
        defaults.set(aliases, forKey: key)
    }
}
