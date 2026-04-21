#!/usr/bin/env bash
# Build, sign, notarize, and staple a Menubar Journal DMG.
#
# Usage:
#   VERSION=1.0.0 NOTARY_PROFILE="Krish Shah" ./scripts/build_release_dmg.sh
#
# Environment:
#   VERSION              Required. Marketing version, e.g. 1.0.0
#   DEVELOPMENT_TEAM     Default: C85X7E88A8
#   CODE_SIGN_IDENTITY   Default: "Developer ID Application"
#   NOTARY_PROFILE       notarytool keychain profile name. If set, notarize + staple.
#                        Otherwise pass NOTARIZE=1 with API_KEY_PATH/API_KEY_ID/API_ISSUER.
#   SKIP_NOTARIZE=1      Build + sign only, skip notarization.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="MenubarJournal"
PROJECT="$ROOT/MenubarJournal.xcodeproj"
VERSION="${VERSION:?Set VERSION (e.g. 1.0.0)}"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
ARCHIVE="$BUILD_DIR/MenubarJournal.xcarchive"
APP_PATH="$ARCHIVE/Products/Applications/MenubarJournal.app"
STAGING="$BUILD_DIR/dmg_stage"
DMG_NAME="MenubarJournal-${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-C85X7E88A8}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-Developer ID Application}"
MARKETING_VERSION="$VERSION"
CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:-$VERSION}"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$STAGING"

echo "==> Archiving $SCHEME $MARKETING_VERSION (build $CURRENT_PROJECT_VERSION)"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE" \
  -destination "platform=macOS" \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$CURRENT_PROJECT_VERSION" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
  OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
  ENABLE_HARDENED_RUNTIME=YES

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: expected app at $APP_PATH" >&2
  exit 1
fi

echo "==> Verifying signature and hardened runtime"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
CODESIGN_INFO="$(codesign -dv --verbose=2 "$APP_PATH" 2>&1 || true)"
echo "$CODESIGN_INFO" | rg -i 'authority|team|flags|identifier' || true
if ! echo "$CODESIGN_INFO" | rg -q 'runtime'; then
  echo "error: hardened runtime flag not set on $APP_PATH" >&2
  exit 1
fi

echo "==> Staging for DMG"
ditto "$APP_PATH" "$STAGING/MenubarJournal.app"

echo "==> Creating compressed DMG"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "Menubar Journal ${VERSION}" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH"

echo "==> Signing DMG"
codesign --sign "$CODE_SIGN_IDENTITY" --timestamp "$DMG_PATH"

if [[ "${SKIP_NOTARIZE:-0}" == "1" ]]; then
  echo "==> SKIP_NOTARIZE=1, skipping notarization"
else
  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    echo "==> Notarizing via keychain profile: $NOTARY_PROFILE"
    xcrun notarytool submit "$DMG_PATH" --wait --keychain-profile "$NOTARY_PROFILE"
  elif [[ -n "${API_KEY_PATH:-}" && -n "${API_KEY_ID:-}" && -n "${API_ISSUER:-}" ]]; then
    echo "==> Notarizing via App Store Connect API key"
    xcrun notarytool submit "$DMG_PATH" --wait \
      --key "$API_KEY_PATH" \
      --key-id "$API_KEY_ID" \
      --issuer "$API_ISSUER"
  else
    echo "error: no notarization credentials. Set NOTARY_PROFILE or API_KEY_* (or SKIP_NOTARIZE=1)." >&2
    exit 1
  fi

  echo "==> Stapling"
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  spctl --assess --type open --context context:primary-signature --verbose "$DMG_PATH" || true
fi

echo "==> Done: $DMG_PATH"
shasum -a 256 "$DMG_PATH"
