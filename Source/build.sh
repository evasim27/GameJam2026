#!/bin/bash
# Exports Lost in Tape for Web, macOS and Windows into ./build
set -e
cd "$(dirname "$0")"
GODOT="${GODOT:-$HOME/Applications/Godot_4.7.2.app/Contents/MacOS/Godot}"
rm -rf build && mkdir -p build/web build/macos build/windows
"$GODOT" --headless --path game --export-release "Web" ../build/web/index.html
"$GODOT" --headless --path game --export-release "macOS" ../build/macos/LostInTape.zip
"$GODOT" --headless --path game --export-release "Windows" ../build/windows/LostInTape.exe
(cd build/web && zip -qr ../LostInTape-web.zip .)
(cd build/windows && zip -qr ../LostInTape-windows.zip .)
cp build/macos/LostInTape.zip build/LostInTape-macos.zip
echo "Done:"; ls -lh build/*.zip
