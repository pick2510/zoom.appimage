#!/bin/bash
# Build a Zoom AppImage from the official zoom_x86_64.tar.xz tarball.
# Usage: ./build.sh [path/to/zoom_x86_64.tar.xz]
# Without an argument the tarball is downloaded from zoom.us. Set ZOOM_VERSION
# (e.g. 7.2.1.5760) to download a specific version instead of the latest.
# The AppImage embeds update information pointing at the GitHub releases of
# this repository (used by Gear Lever / AppImageUpdate); override it with
# UPDATE_INFO, or set UPDATE_INFO= (empty) to leave it out.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
BUILD=build
APPDIR="$BUILD/Zoom.AppDir"
APPIMAGETOOL="$BUILD/appimagetool-x86_64.AppImage"

mkdir -p "$BUILD"

if [ $# -ge 1 ]; then
    TARBALL="$1"
    [ -f "$TARBALL" ] || { echo "Tarball not found: $TARBALL" >&2; exit 1; }
else
    if [ -z "${ZOOM_VERSION:-}" ]; then
        # zoom.us/client/latest redirects to cdn.zoom.us/prod/<version>/...
        URL="$(curl -fsSIL -o /dev/null -w '%{url_effective}' \
            https://zoom.us/client/latest/zoom_x86_64.tar.xz)"
        ZOOM_VERSION="$(basename "$(dirname "$URL")")"
        [[ "$ZOOM_VERSION" =~ ^[0-9.]+$ ]] || {
            echo "Could not determine latest Zoom version from $URL" >&2; exit 1; }
    fi
    TARBALL="$BUILD/zoom_x86_64-$ZOOM_VERSION.tar.xz"
    if [ -f "$TARBALL" ]; then
        echo "Using cached $TARBALL"
    else
        echo "Downloading Zoom $ZOOM_VERSION..."
        curl -fL -o "$TARBALL.part" \
            "https://zoom.us/client/$ZOOM_VERSION/zoom_x86_64.tar.xz"
        mv "$TARBALL.part" "$TARBALL"
    fi
fi
if [ ! -x "$APPIMAGETOOL" ]; then
    echo "Downloading appimagetool..."
    curl -fL -o "$APPIMAGETOOL" \
        https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$APPIMAGETOOL"
fi

echo "Extracting $TARBALL..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR"
tar -xJf "$TARBALL" -C "$APPDIR"

VERSION="$(cat "$APPDIR/zoom/version.txt")"

install -m755 resources/AppRun "$APPDIR/AppRun"
install -m644 resources/zoom.desktop "$APPDIR/zoom.desktop"
install -m644 resources/zoom.png "$APPDIR/zoom.png"
install -Dm644 resources/zoom.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/zoom.png"
ln -sf zoom.png "$APPDIR/.DirIcon"

if [ -z "${UPDATE_INFO+x}" ]; then
    REPO="${GITHUB_REPOSITORY:-$(git remote get-url origin 2>/dev/null \
        | sed -nE 's#^(git@github\.com:|https://github\.com/)([^/]+/[^/]+)$#\2#p' | sed 's#\.git$##')}"
    if [ -n "$REPO" ]; then
        UPDATE_INFO="gh-releases-zsync|${REPO%%/*}|${REPO#*/}|latest|Zoom-*x86_64.AppImage.zsync"
    fi
fi
UPDATE_ARGS=()
if [ -n "${UPDATE_INFO:-}" ]; then
    echo "Update information: $UPDATE_INFO"
    UPDATE_ARGS=(-u "$UPDATE_INFO")
fi

echo "Building AppImage for Zoom $VERSION..."
OUT="Zoom-$VERSION-x86_64.AppImage"
ARCH=x86_64 VERSION="$VERSION" "$APPIMAGETOOL" --appimage-extract-and-run \
    --comp zstd "${UPDATE_ARGS[@]}" "$APPDIR" "$OUT"

echo "Done: $OUT"
