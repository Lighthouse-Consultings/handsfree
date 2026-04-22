# Handsfree — Project Instructions (for Claude Code Automode)

## What this is
A native macOS menu-bar app that records speech via global hotkey, transcribes via OpenAI Whisper, and inserts the text at the current cursor location in any app. Clone of "Blitztext" from the reference video, built to validate the Claude Code Automode + Codex workflow.

## Stack (non-negotiable)
- **Swift 5.9+ / SwiftUI / AppKit hybrid** — min macOS 14 (Sonoma)
- **Xcode 16** — project generated via `xcodegen` from `project.yml`
- **No external UI frameworks.** Native SwiftUI only.
- **SPM dependencies allowed:** `soffes/HotKey` (optional), otherwise stdlib only.

## Architecture
Single app target `Handsfree`. Modules are folders, not SPM sub-packages:

| Folder | Responsibility |
|---|---|
| `App/` | `HandsfreeApp` entry, `MenuBarController` (NSStatusItem + popover) |
| `Audio/` | `AudioRecorder` using `AVAudioEngine` — 16kHz mono WAV buffer |
| `Hotkeys/` | `GlobalHotkeyManager` using `CGEventTap` (Fn-modifier needs tap, not Carbon) |
| `Transcription/` | `WhisperClient` → POST multipart to `/v1/audio/transcriptions` |
| `Postprocess/` | `LLMClient` (Anthropic Messages API) + per-mode system prompts |
| `Injection/` | `TextInjector` — save pasteboard, write transcript, Cmd+V via `CGEvent`, restore pasteboard |
| `Settings/` | SwiftUI Settings popover, `KeychainStore` for API keys |
| `Models/` | `Mode` enum (raw, polished, rage, emoji), `AppConfig` |

## Modes
```swift
enum Mode: String, CaseIterable {
    case raw      // Fn+Shift    — 1:1 transcript, no LLM
    case polished // Fn+Control  — LLM smooths spoken → written German
    case rage     // Fn+Option   — LLM rewrites angry text politely
    case emoji    // Fn+Command  — LLM adds emojis, density configurable
}
```

Push-to-talk default (hold to record, release to transcribe). Toggle mode available in Settings.

## Required macOS permissions (handle in `App/PermissionsCoordinator.swift`)
1. `NSMicrophoneUsageDescription` — Info.plist
2. **Accessibility** — `AXIsProcessTrustedWithOptions` prompt, required for text injection + global hotkeys
3. **Input Monitoring** — required for `CGEventTap` on Fn modifier

First-run flow: check each permission, show a numbered checklist popover with "Open System Settings" deep-links (`x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`).

## Secrets
- API keys go to **Keychain** via `Security.framework`, never `UserDefaults`.
- Keychain service name: `com.lighthouseconsultings.handsfree`.
- Two entries: `openai_api_key`, `anthropic_api_key`.

## Text injection contract
```
1. Save current NSPasteboard.general contents (all types)
2. Clear pasteboard, write transcribed String
3. Post CGEvent sequence: Cmd down, V down, V up, Cmd up
4. Sleep 80ms
5. Restore original pasteboard contents
```
If step 2 fails, skip paste and surface error in menu bar icon state.

## UI spec (from screenshots)
Menubar popover, ~320pt wide:
- Header: "Handsfree" + status dot (grey=not ready, green=ready, red=recording, yellow=transcribing)
- 4 mode rows, each: SF Symbol icon • title • subtitle • hotkey chip
- Footer: "Einstellungen" button + "Beenden" button
- Settings view: tabs "Anpassen | Zugang", same popover, `< Zurück` nav

## Coding conventions
- English identifiers, comments only where WHY is non-obvious
- `async/await` for all I/O; no completion-handler callbacks in new code
- No force-unwraps except for `@IBOutlet`-equivalents and known-safe singletons
- Errors: typed `HandsfreeError` enum, propagate up; surface in UI, never silently swallow
- Logging: `os.Logger` with subsystem `com.lighthouseconsultings.handsfree`

## Build / verify
- `xcodegen` to regenerate `Handsfree.xcodeproj` after editing `project.yml`
- `xcodebuild -scheme Handsfree -destination 'platform=macOS' build` for CI-style verification
- Run in Xcode for local testing (menubar apps need real launch, not test host)

## Out of scope (MVP)
- Local Whisper (phase 6)
- Team password gate (phase 5)
- Windows/Linux — macOS only
- Dock icon — menubar only (`LSUIElement = YES`)
