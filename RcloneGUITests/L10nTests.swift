import Testing
@testable import RcloneGUI

@Suite("L10n Tests")
struct L10nTests {
    @Test("Korean translation exists")
    func koreanTranslation() {
        L10n.locale = "ko"
        #expect(L10n.t("close") == "닫기")
        #expect(L10n.t("cancel") == "취소")
        #expect(L10n.t("delete") == "삭제")
    }

    @Test("English translation exists")
    func englishTranslation() {
        L10n.locale = "en"
        #expect(L10n.t("close") == "Close")
        #expect(L10n.t("cancel") == "Cancel")
        #expect(L10n.t("delete") == "Delete")
    }

    @Test("Missing key returns key itself")
    func missingKey() {
        #expect(L10n.t("nonexistent.key.12345") == "nonexistent.key.12345")
    }

    @Test("All toolbar keys exist")
    func toolbarKeys() {
        L10n.locale = "ko"
        #expect(!L10n.t("toolbar.explore").isEmpty)
        #expect(!L10n.t("toolbar.accounts").isEmpty)
        #expect(!L10n.t("toolbar.search").isEmpty)
        #expect(!L10n.t("toolbar.settings").isEmpty)
    }

    @Test("Locale switching")
    func localeSwitching() {
        L10n.locale = "ko"
        let ko = L10n.t("close")
        L10n.locale = "en"
        let en = L10n.t("close")
        #expect(ko != en)
        L10n.locale = "ko"  // reset
    }
}
