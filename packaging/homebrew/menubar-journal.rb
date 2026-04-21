# Homebrew cask for kshah00/homebrew-tap (same pattern as zipper).
# After each GitHub release, copy this file into your tap repo and set `version` + `sha256`
# to the values from the release notes (or `shasum -a 256` on the downloaded DMG).

cask "menubar-journal" do
  version "1.0.0"
  sha256 "62c34d8459070cbddcf553874165f62d02b3c102078a5b8c8898df9a9f14180e"

  url "https://github.com/kshah00/menubar-journal/releases/download/v#{version}/MenubarJournal-#{version}.dmg"
  name "Menubar Journal"
  desc "Menu bar capture for Apple Journal (via Shortcuts)"
  homepage "https://github.com/kshah00/menubar-journal"

  depends_on macos: ">= :sonoma"

  app "MenubarJournal.app"

  zap trash: [
    "~/Library/Preferences/com.kshah00.MenubarJournal.plist",
  ]
end
