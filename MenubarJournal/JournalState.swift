import Foundation
import Observation

@MainActor
@Observable
final class JournalState {
    private let draftKey = "journalDraft"
    private let shortcutNameKey = "shortcutName"
    private let bookmarkKey = "journalBookmarked"

    var draftText: String
    var shortcutName: String
    /// Third field in the shortcut payload (`Message;bookmark;date;open-in-app`).
    var isBookmarked: Bool

    init() {
        draftText = UserDefaults.standard.string(forKey: draftKey) ?? ""
        shortcutName = UserDefaults.standard.string(forKey: shortcutNameKey) ?? CompanionShortcut.displayName
        isBookmarked = UserDefaults.standard.bool(forKey: bookmarkKey)
    }

    func persistDraft() {
        UserDefaults.standard.set(draftText, forKey: draftKey)
    }

    func persistShortcutName() {
        UserDefaults.standard.set(shortcutName, forKey: shortcutNameKey)
    }

    func persistBookmark() {
        UserDefaults.standard.set(isBookmarked, forKey: bookmarkKey)
    }
}
