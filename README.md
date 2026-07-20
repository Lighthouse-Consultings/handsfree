<div align="center">

# 🔦 Flinktext

### Blitztext, aber fertig.

Diktieren auf dem Mac. Lokal, DSGVO-konform einsetzbar, Made in Germany.
Kein Code, kein Kompilieren: DMG laden, loslegen.

[![Lizenz: MIT](https://img.shields.io/badge/Lizenz-MIT-C5A065.svg)](LICENSE)
[![Plattform: macOS 14+](https://img.shields.io/badge/macOS-14%2B-0C2E4E.svg)](#systemvoraussetzungen)
[![Download DMG](https://img.shields.io/badge/Download-DMG-0C2E4E.svg)](https://github.com/Lighthouse-Consultings/handsfree/releases/latest/download/Flinktext.dmg)

</div>

> Hinweis: Repository und Bundle-ID heißen aus historischen Gründen noch `handsfree` (vormaliger Produktname). Der Marken- und Produktname ist **Flinktext**. Die technische Umbenennung folgt.

---

## Was ist Flinktext?

Eine native macOS-Menüleisten-App zum Diktieren. Hotkey halten, sprechen, loslassen: Der Text erscheint am Cursor, in jeder App. Standardmäßig läuft die Spracherkennung zu 100 % lokal auf deinem Gerät.

Flinktext ist die fertige Version dessen, was die Vorlage [Blitztext](https://github.com/cmagnussen/blitztext) als Idee skizziert hat: kein Quellcode-Bauen, keine Anmeldung, keine Cloud im Standard. Du lädst eine DMG und legst los.

<div align="center">

<!-- PLATZHALTER: Demo-GIF (Hotkey halten -> sprechen -> Text erscheint am Cursor). Ersetzen durch docs/demo.gif -->
`[ DEMO-GIF: Hotkey halten, sprechen, loslassen → Text am Cursor ]`

<!-- PLATZHALTER: Screenshot Menüleisten-Popover mit den 4 Modi. Ersetzen durch docs/screenshot-menubar.png -->
`[ SCREENSHOT: Menüleisten-Popover mit den 4 Modi ]`

</div>

---

## Download (kein Build nötig)

**[Flinktext.dmg herunterladen](https://github.com/Lighthouse-Consultings/handsfree/releases/latest/download/Flinktext.dmg)**

1. DMG öffnen, App in den Programme-Ordner ziehen.
2. Flinktext starten. Beim ersten Start fragt macOS nach Mikrofon-, Bedienungshilfen- und Eingabeüberwachungs-Rechten (nötig für globalen Hotkey und Text am Cursor).
3. Hotkey halten, sprechen, loslassen. Fertig.

Die App ist mit Apple Developer ID signiert und von Apple notarisiert (ab v0.10.0): keine Gatekeeper-Warnung, kein Rechtsklick-Trick nötig. Entwickler:innen, die lieber selbst kompilieren, finden den Weg unter [Build aus dem Quellcode](#build-aus-dem-quellcode-für-entwicklerinnen).

---

## Die 4 Modi

Jeder Modus liegt auf einem eigenen Hotkey-Akkord (Right-Option als Auslöser plus Zusatztaste):

| Modus | Was er tut |
|---|---|
| **Roh** | 1:1-Transkript. Genau dein gesprochenes Wort, ohne Nachbearbeitung. |
| **Poliert** | Entfernt Füllwörter und glättet Grammatik zu sauberem Schriftdeutsch. |
| **Compose** | Sprachbefehl statt Diktat: Du sagst, was geschrieben werden soll, das LLM formuliert es. |
| **Emoji** | Reichert den Text mit passenden Emojis an. ✨ |

Roh läuft komplett ohne Sprachmodell. Poliert, Compose und Emoji nutzen ein Sprachmodell zur Nachbearbeitung, lokal oder optional per Cloud-Backend (siehe unten).

---

## Datenschutz und DSGVO

Flinktext ist für datensensible Umgebungen gebaut: Schulen, Behörden, Institute, Kanzleien, Praxen.

- **Standardmäßig 100 % lokal.** Die Spracherkennung läuft über ein gebündeltes `whisper.cpp` mit on-device-Modellen. Dein Audio verlässt das Gerät nicht.
- **Keine Telemetrie, kein Tracking, kein Account.** Kein Analytics-SDK, kein Crash-Reporter, keine Anmeldung.
- **Keychain-only.** API-Schlüssel liegen ausschließlich im macOS-Schlüsselbund (`ThisDeviceOnly`, kein iCloud-Sync).
- **Open Source (MIT).** Der Code ist öffentlich und prüfbar.
- **Signiert und notarisiert.** Ab v0.10.0 mit Apple Developer ID signiert und von Apple notarisiert (Malware-Scan durch Apple).
- **Prompt-Injection-Hardening** in der Text-Einfügung (Steuerzeichen werden vor dem Einfügen entfernt).
- **DSGVO-konform einsetzbar.** Lokale Verarbeitung im Standard-Modus, AVV auf Anfrage.

**Cloud-Backends sind optional und standardmäßig aus.** Wer mag, kann OpenAI, Anthropic oder ein entferntes Ollama als Nachbearbeitungs-Backend einschalten. Das passiert nur aktiv durch dich, mit deinem eigenen API-Schlüssel. Ohne diese Aktivierung verlässt nichts dein Gerät.

> Flinktext ist nicht „zertifiziert" oder pauschal „rechtssicher". Es ist ein Werkzeug, das DSGVO-konformen Einsatz ermöglicht, weil es im Standard lokal verarbeitet. Die rechtskonforme Einbettung in deine Organisation bleibt dein Verfahren. Einen AVV stellen wir auf Anfrage bereit.

---

## 🧭 Systemvoraussetzungen

- macOS 14 (Sonoma) oder neuer
- Apple Silicon und Intel (Universal Binary inkl. lokalem Whisper). Auf Intel-Macs läuft Whisper CPU-only; empfohlen ist dort das Small-Modell.

---

## Herkunft: der fertige Blitztext

Flinktext steht in der Linie von **[Blitztext](https://github.com/cmagnussen/blitztext)** von cmagnussen (MIT-Lizenz, 171 GitHub-Stars, 67 Forks). Blitztext hat die Idee einer lokalen Mac-Diktier-App populär gemacht, blieb aber „Build-from-Source" und ist seit einigen Commits inaktiv.

Flinktext nimmt diesen Faden auf und liefert die fertige App: DMG laden statt kompilieren, dazu vier Modi, lokale Whisper-Modelle gebündelt und ein klarer DSGVO-Fokus. Dank MIT-Lizenz ist diese Ableitung erlaubt. Dank und Credit an Blitztext.

---

## Build aus dem Quellcode (für Entwickler:innen)

Die meisten Nutzer:innen brauchen das nicht: die [DMG](#download-kein-build-nötig) reicht. Wer selbst bauen möchte:

```bash
git clone https://github.com/Lighthouse-Consultings/handsfree.git
cd handsfree
xcodegen generate   # erzeugt das Xcode-Projekt aus project.yml
xcodebuild -scheme Handsfree -configuration Release build
```

Voraussetzungen: Xcode 16+, `xcodegen`. Das Projekt nutzt reines SwiftUI/AppKit ohne externe Abhängigkeiten. Tests laufen über `xcodebuild test -scheme Handsfree -destination 'platform=macOS,arch=arm64'`. Release-Builds sind Universal (arm64 + x86_64); der x86_64-Pfad lässt sich auf Apple Silicon per `arch -x86_64` unter Rosetta testen.

---

## Lizenz

[MIT](LICENSE). In der Tradition von Blitztext (ebenfalls MIT).

---

## English

### Flinktext: the ready-to-run Blitztext

Local, private dictation for your Mac. No build, no account, no cloud.

Hold a hotkey, speak, release: your text appears at the cursor, in any app. Speech recognition runs **100 % locally by default** via a bundled `whisper.cpp` with on-device models. Your audio never leaves the device.

**Just download and run, no compiling required:**

**[Download Flinktext.dmg](https://github.com/Lighthouse-Consultings/handsfree/releases/latest/download/Flinktext.dmg)**

**Four modes:**
- **Raw** : verbatim transcript, no language model.
- **Polished** : removes filler words, cleans up grammar.
- **Compose** : speak an instruction, the LLM writes it for you.
- **Emoji** : sprinkles in fitting emojis.

**Privacy by default:**
- 100 % local out of the box. Audio stays on your Mac.
- No telemetry, no tracking, no account.
- Keychain-only secrets (`ThisDeviceOnly`, no iCloud sync).
- Open Source (MIT), the code is auditable.
- Cloud backends (OpenAI / Anthropic / remote Ollama) are **opt-in and off by default**: you enable them with your own API key, or nothing ever leaves your device.

**Lineage:** Flinktext is the finished version of [Blitztext](https://github.com/cmagnussen/blitztext) by cmagnussen (MIT, 171 stars, 67 forks), which was build-from-source only and is now inactive. MIT permits this derivative. Credit to Blitztext.

**Requirements:** macOS 14+ (Sonoma), Apple Silicon or Intel (universal binary incl. bundled local Whisper; on Intel it runs CPU-only, the Small model is recommended there).

**Build from source:** see [above](#build-aus-dem-quellcode-für-entwicklerinnen). Most users should just grab the DMG.

License: [MIT](LICENSE).

---

<div align="center">

Ein Produkt von [Lighthouse Consultings](https://lighthouseconsultings.de/flinktext/). ⚓️

</div>
