# Homebrew cask for kshah00/homebrew-tap (same pattern as zipper).
# After each GitHub release, copy this file into your tap repo and set `version` + `sha256`
# to the values from the release notes (or `shasum -a 256` on the downloaded DMG).

cask "menubar-journal" do
  version "1.0.1"
  sha256 "36605e8410fd8f5ac118fdbf85a428ce9ffefb543056445250babfa70c84469d"

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
