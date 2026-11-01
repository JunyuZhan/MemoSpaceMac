#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
APP_NAME="MemoSpaceMac"
DIST="dist"
APP="$DIST/$APP_NAME.app"

swift build -c "$CONFIG"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
SDK="$(xcrun --show-sdk-path)"
TARGET="$(uname -m)-apple-macos14.0"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks" "$APP/Contents/Resources"

swiftc -O -parse-as-library \
    -target "$TARGET" -sdk "$SDK" \
    -I "$BIN_DIR/Modules" \
    -Xcc -fmodule-map-file="$BIN_DIR/AMSMB2.build/module.modulemap" \
    -Xcc -I".build/checkouts/AMSMB2/Dependencies/libsmb2/include" \
    App/*.swift App/Views/*.swift App/Views/Components/*.swift \
    "$BIN_DIR"/MemoSpaceKit.build/*.swift.o \
    -L "$BIN_DIR" -lAMSMB2 \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -o "$APP/Contents/MacOS/$APP_NAME"

cp "$BIN_DIR/libAMSMB2.dylib" "$APP/Contents/Frameworks/"
cp App/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

codesign --force --sign - --timestamp=none \
    "$APP/Contents/Frameworks/libAMSMB2.dylib" >/dev/null
codesign --force --sign - --timestamp=none "$APP" >/dev/null

echo "Built $APP"
