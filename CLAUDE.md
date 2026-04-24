# Handsfree — Project Instructions

**Current version:** v0.7.2 (tagged 2026-04-24)
**Repo:** https://github.com/Lighthouse-Consultings/handsfree (PRIVATE)
**Latest DMG:** https://github.com/Lighthouse-Consultings/handsfree/releases/latest/download/Handsfree.dmg

## What this is
Native macOS menu-bar dictation app. Hold a global hotkey, speak, text appears at cursor in any app. Built as LHC's demo of the Claude Code Automode + Codex workflow, positioned as a Wispr Flow replacement. Fully offline operation possible via bundled statically-linked whisper-cli + Ollama/Gemma.

## Stack (non-negotiable)
- **Swift 5.9+ / SwiftUI / AppKit hybrid** — min macOS 14 (Sonoma)
- **Xcode 16+** — project generated via `xcodegen` from `project.yml`
- **Native SwiftUI only**, no external UI frameworks
- **Universal binary** (arm64 + x86_64) — but bundled `whisper-cli` is arm64-only
- **No SPM dependencies** — stdlib only. `soffes/HotKey` evaluated and dropped (NSEvent monitor works fine for our chord pattern)

## Architecture
Single app target `Handsfree`. Modules are folders, not SPM sub-packages:

| Folder | Responsibility |
|---|---|
| `App/` | `HandsfreeApp` entry, `AppDelegate`, `MenuBarController` (NSStatusItem + popover), `MenuBarView`, `SettingsView`, `AppStatus` (state machine), `Orchestrator` (wires pipeline), `SoundFX` |
| `Audio/` | `AudioRecorder` using `AVAudioEngine` — 16kHz mono Int16 WAV, 60s hard cap |
| `Hotkeys/` | `GlobalHotkeyManager` using `NSEvent.addGlobalMonitorForEvents(matching:.flagsChanged)` — Right-Option as trigger + secondary modifier |
| `Transcription/` | `WhisperClient` (OpenAI API) + `LocalWhisperClient` (shells out to bundled whisper-cli) |
| `Postprocess/` | `LLMClient` (Anthropic Messages API) + `OllamaClient` (HTTP to localhost:11434) + per-mode system prompts |
| `Injection/` | `TextInjector` — save pasteboard changeCount, write transcript, Cmd+V via `CGEvent`, wait for target to consume, restore pasteboard |
| `Settings/` | `SettingsView`, `KeychainStore`, `Preferences` (UserDefaults: backend, llmBackend, styleGuide) |
| `Models/` | `Mode` enum (raw, polished, compose, emoji), `HandsfreeError` |

## Modes (current)
```swift
enum Mode: String, CaseIterable {
    case raw      // ⌥ᴿ + ⇧   — 1:1 transcript, no LLM
    case polished // ⌥ᴿ + ⌃   — LLM smooths spoken → written style
    case compose  // ⌥ᴿ + ⌥ᴸ  — Voice-Instruction + optional Clipboard-Kontext → LLM answer
    case emoji    // ⌥ᴿ + ⌘   — LLM adds emojis, density configurable
}
```

Right-Option is the trigger because Fn-detection via CGEventTap is unreliable across external keyboards (ShortcutRecorder #129, QMK #2179). Push-to-talk default.

## Required macOS permissions (per user, not per Mac)
1. `NSMicrophoneUsageDescription` — Info.plist, macOS prompts on first use
2. **Accessibility** — required for global hotkeys via NSEvent + text injection via CGEvent
3. **Input Monitoring** — also required for key events (overlap with Accessibility)

Since ad-hoc signing produces a new cdhash per rebuild, each version-bump breaks existing TCC grants. Workaround documented in LIES_MICH.txt. Proper fix: Developer ID (99 €/Jahr).

## Secrets
- API keys in **Keychain** (`Security.framework`), never UserDefaults
- Service: `com.lighthouseconsultings.handsfree`
- Accessible: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, `kSecAttrSynchronizable=false`
- Accounts: `openai_api_key`, `anthropic_api_key`

## Text injection contract (see SECURITY.md #2)
```
1. Save current NSPasteboard.general items + changeCount
2. Clear pasteboard, write sanitized transcript (strip C0 control chars)
3. Post CGEvent sequence: Cmd down, V down, V up, Cmd up
4. Poll changeCount until target app pastes (max 1.5s)
5. Restore original pasteboard items — skip if changeCount doesn't match expected
```

## Local Whisper (v0.7.0+)
Statically-linked whisper-cli lives in `vendor/whisper-cli-static` (2.6 MB, arm64, Metal + BLAS + Accelerate compiled in). Rebuild via `./build-static-whisper.sh`. Bundle into .app via `./bundle-whisper.sh <AppPath>`.

**Do NOT go back to dynamic linking against brew's whisper-cpp.** The ggml plugin-loader uses a hardcoded `/opt/homebrew/Cellar/ggml/.../libexec` path that doesn't exist on end-user Macs, and `GGML_BACKEND_PATH` env var only accepts single files (not directories). Static linking sidesteps this entirely.

### Model lookup paths (v0.7.1+)
`LocalWhisperClient.modelSearchPaths()`:
1. `/Users/Shared/.handsfree/models/ggml-large-v3-turbo.bin` (multi-user shared, admin places once)
2. `~/.handsfree/models/ggml-large-v3-turbo.bin` (per-user fallback)

## Model Picker (v0.7.2+)
- `WhisperModel` enum (Turbo 1,5 GB / Small 466 MB / Tiny 75 MB) in `Transcription/WhisperModel.swift`
- `Preferences.whisperModel` persists user choice
- `WhisperModelManager` (singleton, `@MainActor`) manages URLSession downloads + delete + progress
- Download target: `~/.handsfree/models/` (no admin needed). Shared admin path still respected for lookup.
- Settings UI: segmented picker + per-variant row (status / Laden / Abbrechen / Löschen)
- HuggingFace: `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-{tiny,small,large-v3-turbo}.bin`

## UI spec (current, as of v0.7.1)
Menubar popover, 380pt wide, auto-resizes for Settings (up to ~720pt):
- Header: gold mic icon • "Handsfree" headline • status dot + short status label
- **Error banner** (if state is error or notReady): orange background, full message, "Fehler kopieren" button
- 4 mode rows: SF Symbol • title • subtitle • hotkey chip (highlighted when active)
- Footer: Einstellungen + Beenden buttons, small © 2026 LHC line below

Settings has GroupBoxes: Transkription / LLM / Stil-Vorgaben (style guide) / API-Keys / Berechtigungen / Über Handsfree. "Über" has Nico headshot (circular, gold ring), contact block (email `addvalue@lighthouseconsultings.com`, phone `+49 177 3472334`), LHC logo, version number from Bundle.

## Coding conventions
- English identifiers; comments only when WHY is non-obvious
- `async/await` for all I/O; no completion-handler callbacks in new code
- No force-unwraps except for known-safe singletons
- Errors: typed `HandsfreeError` enum — propagate up, surface in UI, never silently swallow
- Logging: `os.Logger` subsystem `com.lighthouseconsultings.handsfree`, `.error` level for user-visible pipeline events (Release build strips `.info` and `.debug`)

## Build + deploy cycle (tested, reproducible)
```bash
cd "Produkte/Handsfree"
# Project is regenerated on any project.yml change:
xcodegen generate

# Universal binary build (project.yml ARCHS alone doesn't propagate, need cmdline):
rm -rf ~/Library/Developer/Xcode/DerivedData/Handsfree-*
xcodebuild -scheme Handsfree -configuration Release \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build

APP=$(find ~/Library/Developer/Xcode/DerivedData -path '*Handsfree*Release*/Handsfree.app' -type d | head -1)

# Bundle statically-linked whisper-cli:
bash ./bundle-whisper.sh "$APP"

# Install:
pkill -f Handsfree.app; rm -rf /Applications/Handsfree.app
cp -R "$APP" /Applications/
codesign --force --deep --sign - /Applications/Handsfree.app
open /Applications/Handsfree.app
```

## Release workflow
Upload BOTH `Handsfree.dmg` (stable filename for `releases/latest/download/` link) AND `Handsfree-v<X.Y.Z>.dmg` (versioned archive):
```bash
gh release create v<X.Y.Z> \
  ~/Desktop/Handsfree-Release/Handsfree.dmg \
  ~/Desktop/Handsfree-Release/Handsfree.zip \
  ~/Desktop/Handsfree-Release/Handsfree-v<X.Y.Z>.dmg \
  ~/Desktop/Handsfree-Release/Handsfree-v<X.Y.Z>.zip \
  --title "v<X.Y.Z> — ..." --notes "..."
```

## Gotchas learned the hard way
1. **AVAudioEngine tap callbacks**: convert + copy to Int16 array synchronously inside the closure. Never `Task { await self.append(buf) }` — engine recycles the buffer, async task gets garbage, Whisper silence-hallucinates "you"
2. **ggml dynamic backend loading** requires brew's hardcoded libexec path — doesn't work on end-user Macs. Static linking is the only clean fix
3. **`GGML_BACKEND_PATH` env var** only accepts single .so file, not directory
4. **macOS 26 Terminal** needs Full Disk Access or `sudo` to modify xattrs on `/Applications/*.app`
5. **Quarantine flag** on ad-hoc signed apps silently blocks Accessibility even after grant — `sudo xattr -dr com.apple.quarantine /Applications/Handsfree.app` before re-granting
6. **Permissions are PER USER** — admin grants don't transfer to other accounts on same Mac
7. **`FileManager.isExecutableFile`** flaky on symlinks — use `resolvingSymlinksInPath` + `fileExists`
8. **CGEventTap Fn-modifier** unreliable across external keyboards → Right-Option chord instead
9. **`.info`-level logs** stripped in Release builds — use `.error` for debug output during development, clean up before release
10. **`codex exec -` + `< /dev/null`** hangs silently — either stdin pipe OR `/dev/null`, not both
11. **`zsh` globs on `(Klammern)` in comments** — strip comment lines when pasting command blocks
12. **Release-Asset-Naming**: parallel upload of versioned + unversioned filenames — stable link + archive simultaneously

## Out of scope (deferred)
- Apple Developer ID signing + notarization — 99 €/Jahr, end user: no right-click-open, no permission-reset
- Intel Mac local Whisper (bundled binary is arm64 only — Intel users need brew or Cloud)
- TTS read-back — Nico explicitly said not needed
- Windows/Linux — macOS only
- Dock icon — menubar only (`LSUIElement = YES` in Info.plist)

## Where things live
- Plan file: `~/.claude/plans/ich-habe-dann-auch-swirling-goblet.md`
- Global memory: `~/.claude/projects/-Users-nicoropnack-Claude-Projects/memory/project_handsfree.md`
- Last session summary: `~/.claude/projects/-Users-nicoropnack-Claude-Projects/memory/CURRENT_SPRINT.md`
- Security threat model: `SECURITY.md` (in repo)
- Version history: `CHANGELOG.md` (in repo)
- User-facing install doc: DMG `LIES_MICH.txt` + repo `README.md`
