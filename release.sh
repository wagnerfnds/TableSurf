#!/bin/zsh
# Gera o TableSurf distribuível: archive assinado com Developer ID (cloud signing),
# DMG e — se existirem credenciais no perfil "TableSurf" do notarytool — notarização
# com staple. Sem notarizar, outros Macs exigem botão-direito → Abrir.
set -euo pipefail
cd "$(dirname "$0")"

TEAM_ID="${TABLESURF_TEAM_ID:-$(cat .team-id 2>/dev/null || true)}"
[[ -n "$TEAM_ID" ]] || { echo "Defina TABLESURF_TEAM_ID ou crie .team-id com o seu Team ID." >&2; exit 1; }
VERSION=$(grep -m1 "MARKETING_VERSION" project.yml | sed 's/.*"\(.*\)".*/\1/')
BUILD_DIR=build/release
ARCHIVE="$BUILD_DIR/TableSurf.xcarchive"
EXPORT="$BUILD_DIR/export"
DMG="build/TableSurf-$VERSION.dmg"

rm -rf "$BUILD_DIR" "$DMG"
mkdir -p "$BUILD_DIR"

xcodegen generate
xcodebuild -project TableSurf.xcodeproj -scheme TableSurf -configuration Release \
    archive -archivePath "$ARCHIVE" DEVELOPMENT_TEAM=$TEAM_ID -allowProvisioningUpdates -quiet

cat > "$BUILD_DIR/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
xcodebuild -exportArchive -archivePath "$ARCHIVE" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
    -exportPath "$EXPORT" -allowProvisioningUpdates -quiet

STAGING="$BUILD_DIR/dmg"
mkdir -p "$STAGING"
cp -R "$EXPORT/TableSurf.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname TableSurf -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
# O certificado Developer ID é cloud-managed (não está no Keychain local): o app dentro
# do DMG já sai assinado pelo exportArchive; assinar o DMG em si é opcional.
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    codesign --force --sign "Developer ID Application" "$DMG"
fi

if xcrun notarytool history --keychain-profile TableSurf >/dev/null 2>&1; then
    echo "→ Notarizando (alguns minutos)…"
    xcrun notarytool submit "$DMG" --keychain-profile TableSurf --wait
    xcrun stapler staple "$DMG"
    echo "✓ DMG notarizado e pronto para distribuir: $DMG"
else
    echo "⚠ Sem credenciais de notarização (perfil 'TableSurf' do notarytool)."
    echo "  O DMG está assinado com Developer ID mas NÃO notarizado — em outros Macs"
    echo "  será preciso botão-direito → Abrir na primeira vez."
    echo "  Para notarizar: xcrun notarytool store-credentials TableSurf \\"
    echo "      --apple-id <seu apple id> --team-id $TEAM_ID"
    echo "  (pede uma app-specific password de account.apple.com) e rode ./release.sh de novo."
    echo "✓ DMG assinado: $DMG"
fi
