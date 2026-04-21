import AppKit
import Foundation

/// The Shortcuts companion users install from iCloud; name must match `JournalState` default unless customized.
enum CompanionShortcut {
    static let displayName = "Menubar Journal Entry"
    static let downloadURL = URL(string: "https://www.icloud.com/shortcuts/d9760d854da047d2aa1bd645e4737fab")!
}

enum ShortcutRunner {
    /// `Message;bookmark;date;open-in-app` — bookmark and open-in-app are `true` / `false`; date is `yyyy-MM-dd HH:mm`.
    static func shortcutTextPayload(message: String, bookmark: Bool, date: Date, openInApp: Bool) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd HH:mm"
        return [
            message,
            bookmark ? "true" : "false",
            df.string(from: date),
            openInApp ? "true" : "false",
        ].joined(separator: ";")
    }

    /// Runs the shortcut without bringing Shortcuts to the foreground (same intent as `open -g`).
    static func runJournalShortcut(
        named shortcutName: String,
        message: String,
        bookmark: Bool,
        date: Date,
        openInApp: Bool
    ) {
        let text = shortcutTextPayload(message: message, bookmark: bookmark, date: date, openInApp: openInApp)
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "run-shortcut"
        components.queryItems = [
            URLQueryItem(name: "name", value: shortcutName),
            URLQueryItem(name: "input", value: "text"),
            URLQueryItem(name: "text", value: text),
        ]

        guard let url = components.url else { return }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false

        NSWorkspace.shared.open(url, configuration: configuration) { _, error in
            if let error {
                NSLog("MenubarJournal: failed to open shortcut URL: \(error.localizedDescription)")
            }
        }
    }

    static func openCompanionShortcutDownloadPage() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open(CompanionShortcut.downloadURL, configuration: configuration) { _, error in
            if let error {
                NSLog("MenubarJournal: failed to open companion shortcut URL: \(error.localizedDescription)")
            }
        }
    }
}
