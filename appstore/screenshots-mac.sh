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
        -derivedDataPath build/dd-mac-screens -only-testing:TableSurfMacUITests/MacScreenshots \
        -resultBundlePath "$dir/result.xcresult" -quiet
    # O runner de UI test do Mac roda em sandbox e não grava fora do container: as
    # capturas saem dos anexos do resultado.
    xcrun xcresulttool export attachments --path "$dir/result.xcresult" --output-path "$dir/anexos" >/dev/null
    python3 - "$dir" <<'PY'
import json, os, shutil, sys
d = sys.argv[1]
for test in json.load(open(f"{d}/anexos/manifest.json")):
    for a in test["attachments"]:
        name = a["suggestedHumanReadableName"].split("_")[0] + ".png"
        shutil.copy(f"{d}/anexos/{a['exportedFileName']}", f"{d}/{name}")
PY
    rm -rf "$dir/anexos" "$dir/result.xcresult"
    /bin/ls "$dir"
done
# Capturas finais (2880×1800) com título, a partir das janelas.
final="$OUT/screenshots/mac"
rm -rf "$final"; mkdir -p "$final"
compose() { swift appstore/compose-mac.swift "$OUT/screenshots/mac-$2/$1.png" "$final/$3.png" "$2" "$4" "$5"; }
compose 01-grid light 01-grid "Tabelas enormes,\nsem espera" "As páginas carregam enquanto você rola. Milhões de linhas, sem travar."
compose 02-console dark 02-console "SQL direto\nao ponto" "Realce, autocomplete e atalhos. Rode a seleção, o comando ou o script inteiro."
compose 03-clientes light 03-clientes "Todos os seus\nbancos" "PostgreSQL, MySQL e SQLite numa interface só — no Mac, no iPhone e no iPad."
compose 01-grid dark 04-escuro "Claro ou escuro" "Feito para o macOS, com a aparência que você preferir."
echo "✓ Capturas em $final"
