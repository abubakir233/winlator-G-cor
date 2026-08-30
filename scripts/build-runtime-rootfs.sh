#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${RUNTIME_OUTPUT_DIR:-${ROOT_DIR}/runtime-cache}"
STAGE_DIR="${ROOTFS_STAGE_DIR:-${ROOT_DIR}/runtime-rootfs}"
OUTPUT="${ROOTFS_OUTPUT:-${ROOT_DIR}/runtime-rootfs.tar.xz}"

"${ROOT_DIR}/scripts/fetch-runtime-assets.sh"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/opt" "$STAGE_DIR/etc"

source "$CACHE_DIR/runtime.env"

proton_dir="$STAGE_DIR/opt/proton-ge"
mkdir -p "$proton_dir"
tar -xzf "$CACHE_DIR/$GE_PROTON_ASSET" -C "$proton_dir" --strip-components=1

# Winlator expects Wine at /opt/wine. Link it to the extracted GE-Proton files tree.
if [[ -d "$proton_dir/files" ]]; then
    ln -sfn proton-ge/files "$STAGE_DIR/opt/wine"
elif [[ -x "$proton_dir/bin/wine" ]]; then
    ln -sfn proton-ge "$STAGE_DIR/opt/wine"
else
    echo "GE-Proton archive does not contain a recognizable files/bin/wine layout" >&2
    exit 1
fi

# GlibcX is a glibc compatibility runtime, not a complete Linux distribution.
# Keep it isolated so Box64/Wine can opt into it without replacing Android Bionic globally.
glibc_dir="$STAGE_DIR/opt/glibc"
mkdir -p "$glibc_dir"
tar -xJf "$CACHE_DIR/$GLIBCX_ASSET" -C "$glibc_dir" --strip-components=1
printf 'WINLATOR_GLIBC_ROOT=/opt/glibc\nWINLATOR_WINE_ROOT=/opt/wine\n' > "$STAGE_DIR/etc/winlator-runtime.env"

rm -f "$OUTPUT"
tar -cJf "$OUTPUT" -C "$STAGE_DIR" opt etc
printf 'ROOTFS_OUTPUT=%q\nGE_PROTON_TAG=%q\nGLIBCX_TAG=%q\n' "$OUTPUT" "$GE_PROTON_TAG" "$GLIBCX_TAG"
