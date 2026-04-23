#!/usr/bin/env bash
# Handsfree — Lokale Transkription einrichten (nur Whisper, ohne Ollama/Gemma)
# ~1,5 GB Download. Audio bleibt komplett lokal auf dem Mac.

set -euo pipefail

echo "Handsfree — Whisper lokal einrichten"
echo "====================================="
echo

# 1. Homebrew pruefen
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew fehlt. Installiere es vorher mit:"
  echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
fi

# 2. whisper-cpp installieren
echo "[1/2] Installiere whisper-cpp via brew..."
brew list whisper-cpp >/dev/null 2>&1 || brew install whisper-cpp
echo "      ✓ Installiert"
echo

# 3. Whisper-Modell laden
MODEL_DIR="$HOME/.handsfree/models"
MODEL_FILE="$MODEL_DIR/ggml-large-v3-turbo.bin"
mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_FILE" ] && [ "$(stat -f%z "$MODEL_FILE" 2>/dev/null || stat -c%s "$MODEL_FILE")" -gt 1000000000 ]; then
  echo "[2/2] Whisper-Modell bereits vorhanden ($MODEL_FILE)"
else
  echo "[2/2] Lade Whisper-Modell (~1,5 GB, 2-5 Min)..."
  curl -L --progress-bar \
    -o "$MODEL_FILE" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
  echo "      ✓ Heruntergeladen"
fi
echo

echo "====================================="
echo "Fertig!"
echo "In Handsfree: Einstellungen -> Transkription -> 'Lokal (whisper.cpp)'"
