#!/usr/bin/env bash
# Filmio: add a Mac Catalyst slice (arm64 + x86_64) to the existing Dovi.xcframework.
# Same crate, tag and flags as build.sh; the other slices are taken from the current xcframework as-is.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
CARGO_DIR="$BUILD_DIR/cargo"
XCFW="$SCRIPT_DIR/Dovi.xcframework"
export PATH="$HOME/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH"

DOVI_TAG="libdovi-3.4.0"
DOVI_REPO_DIR="$BUILD_DIR/dovi_tool"
if [ ! -d "$DOVI_REPO_DIR" ]; then
    mkdir -p "$BUILD_DIR"
    git clone --depth 1 --branch "$DOVI_TAG" https://github.com/quietvoid/dovi_tool.git "$DOVI_REPO_DIR"
fi
CRATE_DIR="$DOVI_REPO_DIR/dolby_vision"

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
CC_PATH="$(xcrun --sdk macosx --find clang)"
for triple in aarch64-apple-ios-macabi x86_64-apple-ios-macabi; do
    echo "==> Building $triple..."
    ( cd "$CRATE_DIR"
      CC="$CC_PATH" CFLAGS="-isysroot $SDK_PATH" \
      cargo cbuild --release --features capi --target "$triple" --target-dir "$CARGO_DIR" )
done

STAGE="$BUILD_DIR/catalyst_stage"
rm -rf "$STAGE"; mkdir -p "$STAGE/maccatalyst/Headers"
lipo -create "$CARGO_DIR/aarch64-apple-ios-macabi/release/libdovi.a" \
             "$CARGO_DIR/x86_64-apple-ios-macabi/release/libdovi.a" \
     -output "$STAGE/maccatalyst/libdovi.a"

# Headers and module map: identical in every slice, take the iOS one.
cp -R "$XCFW/ios-arm64/Headers/." "$STAGE/maccatalyst/Headers/"

OLD="$BUILD_DIR/old-Dovi.xcframework"
rm -rf "$OLD"; cp -R "$XCFW" "$OLD"
ARGS=()
for slice in "$OLD"/*/; do
    slice="${slice%/}"
    case "$(basename "$slice")" in *maccatalyst*) continue ;; esac
    ARGS+=(-library "$slice/libdovi.a" -headers "$slice/Headers")
done
ARGS+=(-library "$STAGE/maccatalyst/libdovi.a" -headers "$STAGE/maccatalyst/Headers")
rm -rf "$XCFW"
xcodebuild -create-xcframework "${ARGS[@]}" -output "$XCFW"
ls "$XCFW"
