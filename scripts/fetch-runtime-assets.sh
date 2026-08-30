#!/usr/bin/env bash
set -euo pipefail

# Resolve and verify runtime assets from official GitHub Releases.
# Override tags with GE_PROTON_TAG or GLIBCX_TAG for reproducible builds.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${RUNTIME_OUTPUT_DIR:-${ROOT_DIR}/runtime-cache}"
mkdir -p "$OUT_DIR"

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }
}
for cmd in curl jq grep sha512sum sha256sum tar; do require_cmd "$cmd"; done

resolve_release() {
    local repo="$1" tag_override="$2"
    if [[ -n "$tag_override" ]]; then
        curl -fsSL "https://api.github.com/repos/${repo}/releases/tags/${tag_override}"
    else
        curl -fsSL "https://api.github.com/repos/${repo}/releases/latest"
    fi
}

fetch_proton() {
    local release_json="$1"
    local tag name url checksum_url checksum_file expected actual
    tag="$(jq -r '.tag_name' <<<"$release_json")"
    name="$(jq -r '.assets[] | select(.name | test("-aarch64\\.tar\\.gz$")) | .name' <<<"$release_json" | head -n1)"
    url="$(jq -r --arg name "$name" '.assets[] | select(.name == $name) | .browser_download_url' <<<"$release_json")"
    checksum_file="$(jq -r '.assets[] | select(.name | test("-aarch64\\.sha512sum$")) | .browser_download_url' <<<"$release_json" | head -n1)"
    [[ -n "$name" && -n "$url" && -n "$checksum_file" ]] || { echo "No ARM64 GE-Proton release asset found for ${tag}" >&2; exit 1; }

    curl -fsSL "$checksum_file" -o "$OUT_DIR/${name}.sha512sum"
    expected="$(awk -v name="$name" '$0 ~ name {print $1; exit}' "$OUT_DIR/${name}.sha512sum")"
    [[ "$expected" =~ ^[0-9a-fA-F]{128}$ ]] || { echo "Could not parse GE-Proton SHA-512 checksum" >&2; exit 1; }
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$OUT_DIR/$name"
    actual="$(sha512sum "$OUT_DIR/$name" | awk '{print $1}')"
    [[ "$actual" == "$expected" ]] || { echo "GE-Proton checksum mismatch" >&2; exit 1; }

    printf 'GE_PROTON_TAG=%q\nGE_PROTON_ASSET=%q\nGE_PROTON_URL=%q\nGE_PROTON_SHA512=%q\n' "$tag" "$name" "$url" "$actual" > "$OUT_DIR/ge-proton.env"
}

fetch_glibcx() {
    local release_json="$1"
    local tag name url expected actual
    tag="$(jq -r '.tag_name' <<<"$release_json")"
    name="$(jq -r '.assets[] | select(.name | test("glibcx-runtime-.*\\.tar\\.xz$")) | .name' <<<"$release_json" | head -n1)"
    url="$(jq -r --arg name "$name" '.assets[] | select(.name == $name) | .browser_download_url' <<<"$release_json")"
    expected="$(jq -r --arg name "$name" '.assets[] | select(.name == $name) | .digest' <<<"$release_json" | sed 's/^sha256://')"
    [[ -n "$name" && -n "$url" && "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || { echo "No verified GlibcX runtime release asset found for ${tag}" >&2; exit 1; }
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$OUT_DIR/$name"
    actual="$(sha256sum "$OUT_DIR/$name" | awk '{print $1}')"
    [[ "$actual" == "$expected" ]] || { echo "GlibcX checksum mismatch" >&2; exit 1; }

    printf 'GLIBCX_TAG=%q\nGLIBCX_ASSET=%q\nGLIBCX_URL=%q\nGLIBCX_SHA256=%q\n' "$tag" "$name" "$url" "$actual" > "$OUT_DIR/glibcx.env"
}

proton_json="$(resolve_release GloriousEggroll/proton-ge-custom "${GE_PROTON_TAG:-}")"
glibcx_json="$(resolve_release dsecurity49/glibcx "${GLIBCX_TAG:-}")"
fetch_proton "$proton_json"
fetch_glibcx "$glibcx_json"
cat "$OUT_DIR/ge-proton.env" "$OUT_DIR/glibcx.env" > "$OUT_DIR/runtime.env"
printf 'RUNTIME_OUTPUT_DIR=%q\n' "$OUT_DIR" >> "$OUT_DIR/runtime.env"
echo "Verified runtime assets written to $OUT_DIR"
cat "$OUT_DIR/runtime.env"
