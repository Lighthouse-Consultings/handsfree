# Handsfree

Native macOS menu-bar dictation app. Hotkey → speak → text at cursor, in any app.

Four modes:
- **Raw** (`Fn+Shift`) — 1:1 transcript
- **Polished** (`Fn+Control`) — spoken → written German
- **Rage → Nice** (`Fn+Option`) — angry input rewritten politely
- **Emoji** (`Fn+Command`) — original text with emojis

## Build

```bash
brew install xcodegen            # one-time
xcodegen generate                # creates Handsfree.xcodeproj
open Handsfree.xcodeproj
```

Then in Xcode: set your Development Team under target signing, `⌘R` to run.

## First run
Grant three permissions in System Settings → Privacy & Security:
1. Microphone
2. Accessibility
3. Input Monitoring

## Config
API keys go into Keychain via the in-app Settings tab. Nothing in plain text.

## Status
Phase 0 scaffold. See `CLAUDE.md` for architecture and `.claude/plans/` for the full plan.
