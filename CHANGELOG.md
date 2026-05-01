# Changelog

## v0.9.0 — 2026-05-01 — DE/EN-Umschalter (App-Lokalisierung)
- **Sprach-Picker oben in den Einstellungen** (System / Deutsch / English) — schaltet die komplette UI-Textdarstellung live um, ohne App-Neustart. Standard `System` folgt der Mac-Sprache.
- Lokalisierte Bereiche: Menubar-Popover (Header, Status-Label, Update-Banner, Footer), Mode-Untertitel (Sprache rein. Text raus. / Speech in. Text out. usw.), kompletter Settings-Dialog (Transkription, LLM, Stil-Vorgaben, API-Keys, Berechtigungen, Updates, Über), Whisper-Modell-Picker inkl. Status-Labels und Tiny/Small-Warnung.
- Markennamen unverändert (Handsfree, Lighthouse Consultings, Hotkey-Symbole).
- Persistenz via `UserDefaults` (`handsfree.appLanguage`), thread-safe `LocalizationManager` mit Lock-protegtem Spiegel — keine Main-Actor-Crashes beim Lookup aus Modell-Code.
- Rationale: Handsfree wird jetzt für englischsprachiges Publikum zugänglich — bisher war alles in Deutsch hartkodiert.

## v0.8.1 — 2026-04-29 — "you"-Halluzination gehärtet
- **Sprache fixiert auf Deutsch** statt Auto-Detect: `LocalWhisperClient` und `WhisperClient` verwenden jetzt `de` als Default. Bei kurzen oder leisen Aufnahmen wurde Englisch fehlerkannt, was die englischen Standard-Halluzinationen ("you", "thanks for watching") triggerte.
- **`-sns` (suppress non-speech tokens)** an `whisper-cli` ergänzt: blockiert Stille-Halluzinationen direkt im Sampler.
- **UI-Warnung in Settings** bei Tiny/Small: orange Hinweistext erklärt, dass kleine Modelle bei Stille `you` halluzinieren können und Turbo für deutsche Diktion empfohlen ist.
- Hintergrund: Tiny/Small-Modelle waren über den Model-Picker (v0.7.2) wählbar, Nutzer mit Tiny-Auswahl bekamen konstant `you` als Output. Fix wirkt für alle Modelle, eliminiert Symptom auch ohne Modellwechsel.

## v0.8.0 — 2026-04-26 — Update-Check & Re-Engagement-Funnel
- **UpdateChecker** (neu): pollt 1x/Tag den öffentlichen GitHub-Releases-Endpoint, erkennt neue Versionen via Semver-Vergleich. Ephemeral URLSession (keine Cookies, kein geteilter Cache), nur User-Agent + Accept-Header — keine Identifikation.
- **Update-Banner** im Menü-Bar-Popover: gold-akzentuiert, zeigt neue Version, "Notes"-Button öffnet GitHub-Release-Seite im Browser
- **Updates-Sektion in Settings:** Toggle für automatische Checks (Default: an), "Jetzt prüfen"-Button für manuelle Aktualisierung, Status-Anzeige (aktuell / Update verfügbar)
- **"Updates per Mail"-Link** in Settings → Über → führt zu `lighthouseconsultings.de/handsfree` (Newsletter-Form, Pull-basiert)
- Privacy bleibt: kein Tracking, kein Heartbeat, keine User-IDs. Nur ein wöchentlicher GitHub-API-Call ohne Auth-Header.

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

## v0.7.1 — 2026-04-23
- Whisper-Modell wird jetzt zusätzlich unter `/Users/Shared/.handsfree/models/` gesucht — Admin kann es einmal zentral ablegen, alle User auf dem Mac nutzen es automatisch
- Kein per-User-Symlink mehr nötig auf Multi-User-Macs

## v0.7.0 — 2026-04-23
- **whisper-cli statisch gelinkt** im App-Bundle — keine Homebrew-Abhängigkeit, keine externen ggml-Plugins, keine dylib-Probleme auf Ziel-Macs
- Voraussetzung für Distribution per DMG: User braucht nur die App + ein Modell, sonst nichts
- Apple Silicon only für Lokal-Whisper (Intel-Macs nutzen Cloud-Backend)

## v0.6.1 — 2026-04-22
- Fehlermeldungen werden vollständig angezeigt (vorher bei 60 Zeichen abgeschnitten)
- "Fehler kopieren"-Button in der Error-Banner

## v0.6.0 — 2026-04-22
- **whisper-cli + Libraries gebündelt** in Handsfree.app — kein `brew install whisper-cpp` mehr nötig für Endnutzer
- App-Größe steigt von 2 MB auf 8 MB, Modell bleibt separat in `~/.handsfree/models/`
- Apple Silicon only (Intel-Macs brauchen weiter Brew oder Cloud-Backend)

## v0.5.2 — 2026-04-22
- Setup-Schritte für Whisper (1,5 GB) und Ollama/Gemma (5 GB) sauber getrennt — User installiert nur was er braucht
- Install-Kommandos inline in `LIES_MICH.txt` und kopierbar aus den App-Settings

## v0.5.1 — 2026-04-22
- **Audio-Pipeline-Fix:** AVAudioEngine-Tap-Buffer werden synchron im Callback konvertiert — vorher sind Samples beim Engine-Recycling verloren gegangen, Whisper halluzinierte "you" auf Stille
- Fresh `AVAudioConverter` pro Buffer (verhindert `.endOfStream`-State-Korruption)
- Reliable `[Int16]`-Copy in den Actor

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
