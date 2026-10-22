#!/bin/sh
# Builds an unsigned Polytechnium.ipa in the folder build/.
# A sideload tool, such as AltStore, SideStore, Sideloadly, or TrollStore, signs it.
set -eu

cd "$(dirname "$0")/.."
xcodegen --quiet
xcodebuild \
  -project Polytechnium.xcodeproj \
  -scheme Polytechnium \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/derived \
  -quiet \
  build

rm -rf build/ipa
mkdir -p build/ipa/Payload
app=build/ipa/Payload/Polytechnium.app
cp -R build/derived/Build/Products/Release-iphoneos/Polytechnium.app "$app"
# A signature with no identity holds the entitlements. A sideload tool reads the
# app group from them, and signs the app again with the account of the user.
for extension in "$app"/PlugIns/*.appex; do
  if [ -d "$extension" ]; then
    codesign --force --sign - --entitlements Widgets/Widgets.entitlements "$extension"
  fi
done
codesign --force --sign - --entitlements App/Polytechnium.entitlements "$app"
(cd build/ipa && zip -qry ../Polytechnium.ipa Payload)
echo "build/Polytechnium.ipa"
