#!/bin/zsh
set -e

cd "$(dirname "$0")"

echo "Building CodexCount..."
swift build -c release 2>&1

APP_DIR="$HOME/Applications/CodexCount.app/Contents/MacOS"
mkdir -p "$APP_DIR"
cp .build/release/CodexCount "$APP_DIR/CodexCount"
cp Info.plist "$HOME/Applications/CodexCount.app/Contents/Info.plist"

echo ""
echo "✅ Instalado em ~/Applications/CodexCount.app"
echo ""
echo "Para iniciar: open ~/Applications/CodexCount.app"
echo "Para iniciar no login: adicione em System Settings → General → Login Items"
