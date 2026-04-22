# Handsfree

Native macOS menubar dictation app. Hold a hotkey, speak, release — text appears at your cursor in any app. Works fully offline.

![icon](docs/icon_1024.png)

Built in ~3h as a demo of the Claude Code Automode + Codex workflow. Complete replacement for Wispr Flow / Superwhisper, with optional local-only operation (no data leaves the Mac).

---

## Modes

| Mode | Hotkey | What it does |
|---|---|---|
| **Raw** | `⌥ᴿ + ⇧` | 1:1 transcript, no LLM |
| **Polished** | `⌥ᴿ + ⌃` | Spoken → clean written style (fillers removed, syntax tightened) |
| **Compose** | `⌥ᴿ + ⌥ᴸ` | Speak an instruction. Optional `⌘C` before = clipboard as context. LLM writes the final text |
| **Emoji** | `⌥ᴿ + ⌘` | Original text with tasteful emojis sprinkled in |

`⌥ᴿ` = Right-Option key (right of spacebar). Hold both, speak, release.

### Compose examples

```
No clipboard:
  Hotkey + "schreib eine Absage an Martin für Donnerstag, freundlich"
  → Full email appears at cursor

With clipboard (Cmd+C a passage first):
  Hotkey + "fass das in 3 Bulletpoints zusammen"
  → 3 bullets replace what you had
```

---

## Backends

Both transcription and LLM can run locally — no API calls needed.

| Layer | Cloud option | Local option |
|---|---|---|
| **Transcription (STT)** | OpenAI `gpt-4o-transcribe` | `whisper.cpp` + `ggml-large-v3-turbo` (1.5 GB) |
| **LLM (Polished/Emoji/Compose)** | Anthropic `claude-sonnet-4-6` | Ollama + `gemma4` (or any Ollama model) |

Toggle in Settings. Raw mode works without any LLM backend. API keys stored in macOS Keychain (`WhenUnlockedThisDeviceOnly`, no iCloud sync).

---

## Install from source

Requirements: macOS 14+, Xcode 16, Apple Silicon.

```bash
git clone git@github.com:nicoroepnack-star/handsfree.git
cd handsfree
brew install xcodegen
xcodegen generate
open Handsfree.xcodeproj
```

In Xcode: select target `Handsfree` → Signing & Capabilities → pick your Team (for Mic+Accessibility to be stable) → ⌘R.

For the local backends:

```bash
# Local Whisper
brew install whisper-cpp
mkdir -p ~/.handsfree/models
curl -L -o ~/.handsfree/models/ggml-large-v3-turbo.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin

# Local LLM
brew install ollama                 # Ollama auto-starts via brew services
ollama pull gemma3                  # or any model; update OllamaClient.swift if different
```

## First run

Grant three macOS permissions (System Settings → Privacy & Security):

1. **Microphone** — prompted automatically at first run
2. **Accessibility** — required for global hotkeys + text injection; add Handsfree.app manually
3. **Input Monitoring** — optional, harmless to add

Open the menubar popover → Settings → paste API keys OR toggle to Local backends.

---

## Style Guide

Settings has a free-text "Stil-Vorgaben" field. Content is appended to every LLM system prompt (both Anthropic and Ollama paths).

Example:

```
Immer Sie-Form, keine Em-Dashes.
Signatur: Beste Grüße, Nico Röpnack — Lighthouse Consultings.
Fachbegriffe: Smartsheet (kein Leerzeichen), FEW Automotive, Bitpanda.
```

Applied to Polished, Emoji, and Compose — not to Raw (Raw bypasses LLM entirely).

---

## Security

Threat model and hardening notes live in [SECURITY.md](SECURITY.md). Key choices:

- Keychain with `WhenUnlockedThisDeviceOnly`, no iCloud sync
- Ephemeral `URLSession` per API client (no cookies / shared cache)
- Pasteboard saved before inject, restored after target consumed (change-count watch, not fixed timer)
- LLM user input wrapped in `<user_speech>…</user_speech>` with prompt-injection guardrail in system prompt
- Recording hard-capped at 60 s
- Control-char strip on inserted text
- Hardened runtime enabled (`ENABLE_HARDENED_RUNTIME=YES`)

---

## Architecture

```
Handsfree/
├── App/             # HandsfreeApp, AppDelegate, MenuBarController, MenuBarView, Orchestrator, AppStatus, SoundFX
├── Audio/           # AudioRecorder (AVAudioEngine → 16 kHz mono WAV)
├── Hotkeys/         # GlobalHotkeyManager (NSEvent flagsChanged, Right-Option + secondary modifier)
├── Transcription/   # WhisperClient (OpenAI) + LocalWhisperClient (whisper.cpp shell-out)
├── Postprocess/     # LLMClient (Anthropic) + OllamaClient (localhost:11434)
├── Injection/       # TextInjector (CGEvent Cmd+V + pasteboard save/restore)
├── Settings/        # KeychainStore, Preferences (UserDefaults), SettingsView
└── Models/          # Mode enum, errors
```

See [CLAUDE.md](CLAUDE.md) for the coding-agent project brief.

---

## Release log

| Tag | Highlights |
|---|---|
| v0.4.0 | Style Guide field, start-sound (Purr), success/failure silent per request |
| v0.3.0 | Compose mode, Ollama/Gemma LLM backend, app icon |
| v0.2.x | Local whisper.cpp, live status refresh, auto-language detect |
| v0.1.x | Scaffold, full pipeline, security hardening |

Full log: `git log --oneline`. Rollback: `git checkout v0.3.0`.

---

## Known limitations

- **Ad-hoc code signing** resets Accessibility permission on every rebuild. Fix: Apple Developer ID ($99/year), then stable across builds.
- **Apple Silicon only** — not built for Intel Macs. Build from source on an Intel Mac if needed (Xcode will retarget).
- **Ollama must be running** for local LLM. `brew services list` should show ollama as `started`.
- **No local TTS** — app only does STT + text insertion, no read-back. Could add `say` command or OpenAI TTS later.

---

## License / distribution

Private repo for now. If open-sourced later: MIT or Apache 2.0. No user-data telemetry. API keys never leave the device except as Authorization headers to OpenAI / Anthropic (when cloud backend selected).
