import SwiftUI

@main
struct MenubarJournalApp: App {
    @State private var journal = JournalState()

    var body: some Scene {
        MenuBarExtra("Journal", systemImage: "bookmark.fill") {
            JournalPopoverView()
                .environment(journal)
        }
        .menuBarExtraStyle(.window)
    }
}
