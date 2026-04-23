#!/usr/bin/env bash
# Handsfree — Lokale KI einrichten (Whisper + Gemma via Ollama)
# Usage: curl -fsSL https://raw.githubusercontent.com/Lighthouse-Consultings/handsfree/main/setup-local.sh | bash

set -euo pipefail

echo "Handsfree — Lokale KI-Einrichtung"
echo "=================================="
echo

# 1. Homebrew prüfen
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew fehlt. Installiere Homebrew zuerst:"
  echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
fi

# 2. whisper-cpp + ollama installieren
echo "[1/4] Installiere whisper-cpp + ollama via brew..."
brew list whisper-cpp >/dev/null 2>&1 || brew install whisper-cpp
brew list ollama      >/dev/null 2>&1 || brew install ollama
echo "      ✓ Installiert"
echo

# 3. Whisper-Modell laden (1,5 GB)
MODEL_DIR="$HOME/.handsfree/models"
MODEL_FILE="$MODEL_DIR/ggml-large-v3-turbo.bin"
mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_FILE" ] && [ "$(stat -f%z "$MODEL_FILE" 2>/dev/null || stat -c%s "$MODEL_FILE")" -gt 1000000000 ]; then
  echo "[2/4] Whisper-Modell bereits vorhanden ($MODEL_FILE)"
else
  echo "[2/4] Lade Whisper-Modell (~1,5 GB, dauert 2-5 Min)..."
  curl -L --progress-bar \
    -o "$MODEL_FILE" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
  echo "      ✓ Heruntergeladen"
fi
echo

# 4. Ollama Service starten + Gemma ziehen
echo "[3/4] Starte Ollama Service..."
brew services list | grep -q "ollama.*started" || brew services start ollama
sleep 2
echo "      ✓ Läuft auf http://127.0.0.1:11434"
echo

echo "[4/4] Lade Gemma-Modell (~5 GB, dauert 3-10 Min beim ersten Mal)..."
ollama pull gemma3 || ollama pull gemma2
echo "      ✓ Heruntergeladen"
echo

echo "=================================="
echo "Fertig!"
echo
echo "Öffne jetzt Handsfree → Einstellungen:"
echo "  • Transkription: 'Lokal (whisper.cpp)' auswählen"
echo "  • LLM: 'Lokal (Ollama)' auswählen"
echo
echo "Der Status-Punkt sollte grün werden. Viel Spaß beim Reden."
