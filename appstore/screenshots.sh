#!/bin/zsh
# Capturas do iPhone e do iPad para a App Store, com o banco "Loja (demo)".
#
#   appstore/screenshots.sh      → build/appstore/screenshots/{iphone,ipad}
set -euo pipefail
cd "$(dirname "$0")/.."

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
BUNDLE=dev.tablesurf.app
OUT=build/appstore
DD=build/dd-screens
typeset -A DEVICES
DEVICES=(iphone "iPhone 18 Pro Max" ipad "iPad Pro 13-inch (M5)")

xcodegen generate -q
python3 appstore/demo-db.py "$OUT/loja.sqlite" >/dev/null
xcodebuild -project TableSurf.xcodeproj -scheme TableSurfMobile -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD" -quiet build-for-testing
xctestrun=$(/bin/ls "$DD"/Build/Products/*.xctestrun | head -1)
app="$DD/Build/Products/Debug-iphonesimulator/TableSurf.app"

for key in iphone ipad; do
    name=${DEVICES[$key]}
    udid=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"].values()
print(next((d["udid"] for group in devices for d in group if d["name"] == sys.argv[1]), ""))
' "$name")
    [[ -n "$udid" ]] || { echo "simulador não encontrado: $name" >&2; exit 1; }
    echo "→ $name"
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b >/dev/null
    xcrun simctl ui "$udid" appearance light
    xcrun simctl status_bar "$udid" override --time "9:41" --dataNetwork wifi --wifiMode active \
        --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
    xcrun simctl uninstall "$udid" "$BUNDLE" 2>/dev/null || true
    xcrun simctl install "$udid" "$app"

    # Conexões de exemplo: só a SQLite abre; as outras são fictícias, para a lista.
    data=$(xcrun simctl get_app_container "$udid" "$BUNDLE" data)
    mkdir -p "$data/Documents/Databases" "$data/Library/Application Support/TableSurf"
    cp "$OUT/loja.sqlite" "$data/Documents/Databases/loja.sqlite"
    python3 appstore/seed-workspaces.py "$data/Library/Application Support/TableSurf/workspaces.json"

    dir="$PWD/$OUT/screenshots/$key"
    rm -rf "$dir"; mkdir -p "$dir"
    TEST_RUNNER_TABLESURF_SHOTS="$dir" xcodebuild test-without-building -xctestrun "$xctestrun" \
        -destination "id=$udid" -only-testing:TableSurfMobileUITests/AppStoreScreenshots -quiet
    xcrun simctl status_bar "$udid" clear
    swift appstore/normalize.swift "$dir"/*.png >/dev/null
    /bin/ls "$dir"
done
echo "✓ Capturas em $OUT/screenshots"
