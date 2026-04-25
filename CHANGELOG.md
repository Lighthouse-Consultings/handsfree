# Changelog

## v0.7.3 — 2026-04-25 — Pre-Public Cleanup
- **Privacy:** Diktat-Inhalte landen nicht mehr im macOS Unified Log (zuvor wurde der Anfang jedes Transkripts auf `.error`-Level mit `privacy: .public` geloggt — andere Prozesse mit Log-Zugriff hätten sie lesen können)
- **Privacy:** `X-Handsfree-Model`-Header beim Modell-Download an HuggingFace entfernt (war redundant zur URL und ein unnötiges Identifikations-Signal)
- **Sicherheit:** Compose-Mode hat jetzt einen SICHERHEIT-Block im System-Prompt, der Clipboard- und Voice-Inhalt explizit als unvertraute Daten kennzeichnet (Prompt-Injection-Schutz)
- GitHub-Link im "Über"-Tab korrigiert auf `Lighthouse-Consultings/handsfree`
- `.gitignore`: lokale Tooling-Artefakte (`.observer.lock`, `observer.log`) ausgeschlossen

## v0.7.2 — 2026-04-24
- **Model Picker in Settings** — segmented picker für Turbo (1,5 GB) / Small (466 MB) / Tiny (75 MB), kein Terminal mehr nötig
- **Eingebauter Downloader** mit Progress-Bar, Cancel und Löschen pro Modell-Variante — Download landet in ~/.handsfree/models/
- `LocalWhisperClient.modelFileName` / `modelSearchPaths()` jetzt dynamisch (folgen `Preferences.whisperModel`)
- Fehlermeldungen im Orchestrator zeigen den gewählten Modellnamen statt hartkodiertem Turbo-Pfad
- Rationale: schwache Macs (M2 8GB) sind mit Turbo zu langsam, Tiny/Small als Low-RAM-Option ohne brew/curl

## v0.5.0 — 2026-04-23
- **Universal Binary** (arm64 + x86_64) — runs natively on Apple Silicon and Intel Macs
- **Über-Handsfree** section in Settings with LHC logo, contact info, website/GitHub links, version
- Discrete `© 2026 LHC` line in menubar popover footer
- Version bumped to 0.5.0, copyright entry in Info.plist


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
