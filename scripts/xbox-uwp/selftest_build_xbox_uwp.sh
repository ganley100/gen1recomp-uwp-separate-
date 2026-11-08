#!/usr/bin/env bash
# Offline checks for the Xbox UWP build entry points.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

require_command zip
require_command unzip

say "checking shell entry points"
bash -n "$ROOT/scripts/build_xbox_uwp.sh" "$SCRIPT_DIR"/*.sh
help="$(bash "$ROOT/scripts/build_xbox_uwp.sh" --help)"
printf '%s' "$help" | grep -q -- '--version X.Y.Z' \
  || fail "build help does not document --version"

say "checking the shared game.love payload"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gen1recomp-uwp-selftest.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT
love_file="$temp_dir/game.love"
listing="$temp_dir/love-listing.txt"
"$ROOT/scripts/pack_love.sh" \
  --output "$love_file" \
  --listing "$listing" \
  --version 1.2.3 \
  --dry-run >/dev/null
unzip -p "$love_file" src/core/Version.lua \
  | grep -Eq 'engine[[:space:]]*=[[:space:]]*"1\.2\.3"' \
  || fail "shared payload version was not stamped"

say "checking the manifest template"
grep -q '@UWP_PACKAGE_VERSION@' "$UWP_ROOT/Package.appxmanifest.in" \
  || fail "manifest template is missing the package version placeholder"
grep -q '@UWP_PUBLISHER_XML@' "$UWP_ROOT/Package.appxmanifest.in" \
  || fail "manifest template is missing the publisher placeholder"

for placeholder in UWP_PROJECT UWP_DISPLAY_NAME UWP_PHONE_PRODUCT_ID UWP_EXTRA_CAPABILITIES; do
  grep -q "@$placeholder@" "$UWP_ROOT/Package.appxmanifest.in" \
    || fail "manifest template is missing @$placeholder@"
done

say "checking the single-game packages"
for game in red ruby; do
  for preset in "uwp-$game-release" "uwp-$game-relwithdebinfo"; do
    grep -q "\"name\": \"$preset\"" "$UWP_ROOT/CMakePresets.json" \
      || fail "missing CMake preset $preset"
  done
  for asset in Square44x44Logo StoreLogo SmallTile Square150x150Logo LargeTile WideTile SplashScreen; do
    [ -f "$UWP_ROOT/Assets/$game/$asset.png" ] \
      || fail "missing $game asset $asset.png"
  done
done
grep -q 'DevelopmentFiles\\\\Gen1Recomp Red' "$UWP_ROOT/CMakeLists.txt" \
  || fail "Red package does not read D:\\DevelopmentFiles\\Gen1Recomp Red"
grep -q 'DevelopmentFiles\\\\Gen1Recomp Ruby' "$UWP_ROOT/CMakeLists.txt" \
  || fail "Ruby package does not read D:\\DevelopmentFiles\\Gen1Recomp Ruby"

bash "$SCRIPT_DIR/write_build_info.sh" \
  "$temp_dir/build-info.json" 1.2.3 Release >/dev/null
grep -q '"version": "1.2.3"' "$temp_dir/build-info.json" \
  || fail "build metadata does not contain the requested version"

say "Xbox UWP self-test passed"
