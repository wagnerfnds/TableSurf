#!/bin/zsh
# Compila o TableSurf em Release, instala em /Applications e re-assina o bundle.
# A re-assinatura é obrigatória: com assinatura ad-hoc, app e framework embutido
# precisam da MESMA identidade, senão o dyld recusa o TableSurfCore ("different Team IDs").
set -euo pipefail
cd "$(dirname "$0")"

xcodegen generate
xcodebuild -project TableSurf.xcodeproj -scheme TableSurf -configuration Release \
    -destination 'platform=macOS' -quiet build

apps=(~/Library/Developer/Xcode/DerivedData/TableSurf-*/Build/Products/Release/TableSurf.app)
app="${apps[1]}"

pkill -x TableSurf 2>/dev/null || true
rm -rf /Applications/TableSurf.app
ditto "$app" /Applications/TableSurf.app
codesign --force --sign - /Applications/TableSurf.app/Contents/Frameworks/TableSurfCore.framework
codesign --force --sign - /Applications/TableSurf.app

echo "✓ TableSurf instalado em /Applications"
open /Applications/TableSurf.app
