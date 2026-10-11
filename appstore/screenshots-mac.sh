#!/bin/zsh
# Capturas do Mac para a App Store (janela em claro e escuro), com o banco "Loja (demo)".
#
#   appstore/screenshots-mac.sh   → build/appstore/screenshots/mac-{light,dark}
#
# O app roda com CFFIXED_USER_HOME apontando para uma home fictícia em build/: as
# conexões e preferências reais de quem roda ficam fora das capturas.
set -euo pipefail
cd "$(dirname "$0")/.."

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
OUT="$PWD/build/appstore"
HOME_DEMO="$OUT/mac-home"

rm -rf "$HOME_DEMO"
mkdir -p "$HOME_DEMO/Documents" "$HOME_DEMO/Library/Application Support/TableSurf"
python3 appstore/demo-db.py "$HOME_DEMO/Documents/loja.sqlite" >/dev/null
python3 appstore/seed-workspaces.py "$HOME_DEMO/Library/Application Support/TableSurf/workspaces.json" \
    "$HOME_DEMO/Documents/loja.sqlite"

xcodegen generate -q
for appearance in light dark; do
    dir="$OUT/screenshots/mac-$appearance"
    rm -rf "$dir"; mkdir -p "$dir"
    TEST_RUNNER_TABLESURF_SHOTS="$dir" TEST_RUNNER_TABLESURF_DEMO_HOME="$HOME_DEMO" \
    TEST_RUNNER_TABLESURF_APPEARANCE="$appearance" \
    xcodebuild test -project TableSurf.xcodeproj -scheme TableSurf -destination 'platform=macOS,arch=arm64' \
        -derivedDataPath build/dd-mac-screens -only-testing:TableSurfMacUITests/MacScreenshots -quiet
    /bin/ls "$dir"
done
echo "✓ Capturas em $OUT/screenshots/mac-*"
