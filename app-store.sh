#!/bin/zsh
# Gera e envia o TableSurf para o App Store Connect (iOS/iPadOS e macOS, mesmo bundle
# dev.tablesurf.app — compra universal). Assina pela conta logada no Xcode.
#
#   ./app-store.sh            → archive + upload dos dois
#   ./app-store.sh ios        → só iOS/iPadOS
#   ./app-store.sh mac        → só macOS (com sandbox)
#   ./app-store.sh … --no-upload  → só gera o .ipa/.pkg em build/app-store
#
# O Team ID vem de TABLESURF_TEAM_ID ou do arquivo .team-id (fora do git).
set -euo pipefail
cd "$(dirname "$0")"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
TEAM_ID="${TABLESURF_TEAM_ID:-$(cat .team-id 2>/dev/null || true)}"
[[ -n "$TEAM_ID" ]] || { echo "Defina TABLESURF_TEAM_ID ou crie .team-id com o seu Team ID." >&2; exit 1; }

platforms=()
destination=upload
for arg in "$@"; do
    case "$arg" in
        ios|mac) platforms+=("$arg") ;;
        --no-upload) destination=export ;;
        *) echo "argumento desconhecido: $arg" >&2; exit 1 ;;
    esac
done
(( ${#platforms} )) || platforms=(ios mac)

OUT=build/app-store
mkdir -p "$OUT"
xcodegen generate

cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>$destination</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
PLIST

for platform in $platforms; do
    archive="$OUT/TableSurf-$platform.xcarchive"
    rm -rf "$archive" "$OUT/$platform"
    if [[ "$platform" == ios ]]; then
        echo "→ Archive iOS/iPadOS"
        xcodebuild -project TableSurf.xcodeproj -scheme TableSurfMobile -configuration Release \
            -destination 'generic/platform=iOS' archive -archivePath "$archive" \
            DEVELOPMENT_TEAM="$TEAM_ID" -allowProvisioningUpdates -quiet
    else
        echo "→ Archive macOS (sandbox)"
        # O target macOS assina ad-hoc ("-") para o install.sh; aqui a identidade vem da
        # assinatura automática do time.
        xcodebuild -project TableSurf.xcodeproj -scheme TableSurf -configuration Release \
            -destination 'generic/platform=macOS' archive -archivePath "$archive" \
            DEVELOPMENT_TEAM="$TEAM_ID" TABLESURF_DISTRIBUTION=AppStore CODE_SIGN_IDENTITY="Apple Development" \
            -allowProvisioningUpdates -quiet
    fi
    if [[ "$platform" == mac ]]; then
        # Os bundles de recursos dos pacotes Swift (swift-crypto, swift-nio…) saem do
        # build assinados com o certificado de desenvolvimento, e o export não os
        # re-assina: a Apple recusa o upload (ITMS-90284). Sem código dentro, eles não
        # precisam de assinatura própria — a do app já sela o conteúdo.
        for bundle in "$archive"/Products/Applications/*.app/Contents/Resources/*.bundle(N); do
            [[ -d "$bundle/Contents/MacOS" ]] || rm -rf "$bundle/Contents/_CodeSignature"
        done
    fi
    echo "→ Export ($destination) $platform"
    xcodebuild -exportArchive -archivePath "$archive" -exportOptionsPlist "$OUT/ExportOptions.plist" \
        -exportPath "$OUT/$platform" -allowProvisioningUpdates -quiet
done

if [[ "$destination" == upload ]]; then
    echo "✓ Enviado ao App Store Connect — o build aparece em TestFlight após o processamento."
else
    echo "✓ Pacotes em $OUT/{ios,mac}"
fi
