# Changelog

## v0.4.0 — 2026-04-22
- **Style Guide field** in Settings: persistent instructions appended to every LLM call (Polished / Emoji / Compose, both Anthropic and Ollama paths)
- **Start sound** `Purr` when recording begins. Success/failure silent by user preference
- `ScrollView` wrap on Settings for longer popover

## v0.3.0 — 2026-04-22
- **Compose mode** (`⌥ᴿ + ⌥ᴸ`): voice instruction + optional clipboard context → LLM writes output at cursor. Replaces Rage mode.
- **Ollama / Gemma local LLM backend** (`OllamaClient`), toggle in Settings
- LHC-branded app icon (Navy gradient + gold waveform, generated via CoreGraphics)
- Auto-language detect (`whisper -l auto`, OpenAI language param omitted)
- Hotkey fix: Right-Option held state tracked across subsequent flagsChanged events

## v0.2.x — 2026-04-22
- Local `whisper.cpp` backend (ggml-large-v3-turbo, ~1.5 GB)
- Live status refresh on backend switch + API key save (via `NotificationCenter`)
- Symlink-safe detection of `whisper-cli`
- Inline reason for "Nicht bereit" states

## v0.1.x — 2026-04-22
- Phase 0 scaffold: CLAUDE.md, project.yml, module stubs
- Phase 0.1 security hardening: Keychain ACL, pasteboard change-count restore, prompt-injection guardrail, ephemeral URLSession, 4 MB WAV cap, control-char strip, Right-Option chord default (Fn unreliable)
- Phase 1 full pipeline: AVAudioEngine recorder + Orchestrator + SettingsView + AppStatus state machine
