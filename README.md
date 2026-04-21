# Menubar Journal

A tiny Mac app that lives in your menu bar and writes into Apple Journal.

Click the icon, type a thought, hit Save. That's the whole app.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Apple Silicon + Intel](https://img.shields.io/badge/Universal-Apple%20Silicon%20%2B%20Intel-lightgrey) [![Latest release](https://img.shields.io/github/v/release/kshah00/menubar-journal)](https://github.com/kshah00/menubar-journal/releases/latest)

## Why this exists

Apple's Journal app is great, but it only exists inside Journal. If a thought hits you while you're in another app, you have to stop, switch over, wait, and by then you've lost the thread.

This fixes that. The menu bar is always there, so a quick entry is one click away. The app doesn't replace Journal — it just hands your text to Journal through a Shortcut so everything still ends up in one place.

## What it looks like

Click the menu bar icon and a small popover opens: a text box, a bookmark toggle, a date, and two buttons — **Save** and **Open**.

- **Save** (⌘S): sends the text to Journal in the background and clears the editor so you can keep going.
- **Open** (⌘O): same thing, but opens Journal afterward so you can see the entry.

That's it. No dock icon, no window, no sidebar, no tags, no AI assistant nagging you.

## Install

> Requires **macOS 14 Sonoma** or later, plus the built-in **Journal** and **Shortcuts** apps. Works on Apple Silicon and Intel.

### Option 1 — Homebrew (recommended)

```bash
brew install --cask kshah00/tap/menubar-journal
```

If Homebrew asks you to tap first, run `brew tap kshah00/tap` and try again.

### Option 2 — Download the DMG

1. Grab **`MenubarJournal-<version>.dmg`** from the [latest release](https://github.com/kshah00/menubar-journal/releases/latest).
2. Open it and drag **Menubar Journal** into **Applications**.
3. Launch it from Spotlight or Launchpad.

The DMG is signed with a Developer ID certificate and notarized by Apple, so macOS opens it without scary warnings.

### One more step: add the companion shortcut

Apple doesn't let third-party apps write to Journal directly — everything has to go through Shortcuts. So there's a one-time setup:

**Add this shortcut:** [Menubar Journal Entry (iCloud link)](https://www.icloud.com/shortcuts/d9760d854da047d2aa1bd645e4737fab)

Open it in Shortcuts on your Mac, hit **Add Shortcut**, and you're done. The app will walk you through this on first launch, and you can always get back to the link from the **⋯** menu inside the popover.

If you've renamed the shortcut, open **⋯ → Change companion shortcut name…** and type the new name.

## Daily use

- Click the icon, type, ⌘S. Done.
- Close the popover mid-sentence and your draft stays put until you come back.
- Tap the bookmark icon if this one matters.
- Tap the date pill to backdate an entry or set a specific time.
- Keyboard-only: `⌘S` to save, `⌘O` to save and open Journal.

## Privacy

The app doesn't talk to any server. Your draft, the shortcut name, and your bookmark preference are stored in UserDefaults on your Mac. Nothing leaves your machine until you press Save or Open — at which point Shortcuts runs locally and hands the text to Journal. No accounts, no telemetry, no analytics.

## Build it yourself

```bash
git clone https://github.com/kshah00/menubar-journal.git
cd menubar-journal
open MenubarJournal.xcodeproj
```

Pick the **MenubarJournal** scheme and Run. No extra dependencies.

## License

[MIT](LICENSE). Do whatever you want with it. PRs and issues welcome.

---

<details>
<summary>Maintainer notes: cutting a release</summary>

There's no CI. Releases are built locally.

```bash
VERSION=1.0.2 NOTARY_PROFILE="Krish Shah" ./scripts/build_release_dmg.sh
gh release create v1.0.2 build/MenubarJournal-1.0.2.dmg \
  --title "Menubar Journal 1.0.2" --generate-notes
```

The script archives, signs with the Developer ID cert, builds the DMG, notarizes via `notarytool` using the stored keychain profile, and staples the ticket. The last line prints the SHA-256 — paste that and the new version into `packaging/homebrew/menubar-journal.rb`, then mirror the file into [kshah00/homebrew-tap](https://github.com/kshah00/homebrew-tap).

</details>
