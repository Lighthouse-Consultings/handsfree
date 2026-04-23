#!/usr/bin/env bash
# Handsfree — Lokales LLM einrichten (Ollama + Gemma, nur fuer Polished/Compose/Emoji)
# ~5 GB Download. Texte verlassen den Mac nie.

set -euo pipefail

echo "Handsfree — Ollama + Gemma lokal einrichten"
echo "============================================"
echo

# 1. Homebrew pruefen
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew fehlt. Installiere es vorher mit:"
  echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
fi

# 2. Ollama installieren
echo "[1/3] Installiere Ollama via brew..."
brew list ollama >/dev/null 2>&1 || brew install ollama
echo "      ✓ Installiert"
echo

# 3. Service starten
echo "[2/3] Starte Ollama-Service..."
brew services list | grep -q "ollama.*started" || brew services start ollama
sleep 2
echo "      ✓ Laeuft auf http://127.0.0.1:11434"
echo

# 4. Gemma ziehen
echo "[3/3] Lade Gemma-Modell (~5 GB, 3-10 Min)..."
ollama pull gemma3 || ollama pull gemma2
echo "      ✓ Heruntergeladen"
echo

echo "============================================"
echo "Fertig!"
echo "In Handsfree: Einstellungen -> LLM -> 'Lokal (Ollama)'"
