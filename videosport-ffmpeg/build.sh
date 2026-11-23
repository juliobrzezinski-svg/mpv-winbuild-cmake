#!/usr/bin/env bash
# videoSport: cross-compiles a minimal, fully static GPL FFmpeg (ffmpeg.exe + ffprobe.exe, no DLLs) for Windows
# x86_64 on Ubuntu with the distro mingw-w64 toolchain. External libraries: libx264, libvpx, libopus, libdav1d,
# zlib (all pinned in versions.sh). All native FFmpeg decoders/encoders/demuxers/muxers/parsers/filters and file
# protocols are kept; network, ffplay, docs and autodetection are disabled.
#
# Usage: videosport-ffmpeg/build.sh <workdir> <outdir>
#   <outdir>/package/<NAME>/   ffmpeg.exe, ffprobe.exe, licenses/, README.txt
#   <outdir>/sources/          one source archive per component + the recipe + SOURCES.md
# Requires: mingw-w64 nasm meson ninja-build pkg-config make curl git python3.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
RECIPE_ROOT=$(cd "$HERE/.." && pwd)
# shellcheck source=versions.sh
source "$HERE/versions.sh"

W=$(mkdir -p "$1" && cd "$1" && pwd)
OUT=$(mkdir -p "$2" && cd "$2" && pwd)
HOST=x86_64-w64-mingw32
P=$W/prefix
S=$W/src
DATE=${BUILD_DATE:-$(date -u +%Y%m%d)}
NAME=${PKG_NAME:-videosport-ffmpeg-n8.0.1-x86_64-$DATE}
JOBS=$(nproc)
mkdir -p "$P/lib/pkgconfig" "$P/include" "$S" "$OUT/sources"

export PKG_CONFIG_LIBDIR="$P/lib/pkgconfig"
export PKG_CONFIG_PATH=""
export CFLAGS="-O2 -I$P/include"
export LDFLAGS="-L$P/lib"

log() { echo "::group::$*" 2>/dev/null || true; echo "=== $*"; }
endlog() { echo "::endgroup::" 2>/dev/null || true; }

# fetch_git <dir> <url> <ref> <commit>: shallow fetch of the pinned commit, verified, plus a source archive.
fetch_git() {
    local dir=$1 url=$2 ref=$3 commit=$4 name
    name=$(basename "$dir")
    rm -rf "$dir"; git init -q "$dir"
    if ! git -C "$dir" fetch -q --depth=1 "$url" "$commit"; then
        git -C "$dir" fetch -q --depth=1 "$url" "$ref"
    fi
    local got
    got=$(git -C "$dir" rev-parse 'FETCH_HEAD^{commit}')
    if [[ "$got" != "$commit" ]]; then echo "ERROR: $name: expected $commit, got $got"; exit 1; fi
    git -C "$dir" -c advice.detachedHead=false checkout -q "$commit"
    # keep the tag name so "git describe" (FFmpeg version string) reports e.g. n8.0.1
    if [[ "$ref" == refs/tags/* ]]; then git -C "$dir" tag "${ref#refs/tags/}" "$commit"; fi
    git -C "$dir" archive --format=tar --prefix="$name-${commit:0:12}/" "$commit" | gzip -9 \
        > "$OUT/sources/src-$name-${commit:0:12}.tar.gz"
}

# fetch_tarball <dir> <url> <sha256>: download, verify, extract, keep the original tarball as the source.
fetch_tarball() {
    local dir=$1 url=$2 sha=$3 file
    file="$OUT/sources/src-$(basename "$url")"
    curl -fsSL --retry 3 -o "$file" "$url"
    echo "$sha  $file" | sha256sum -c -
    rm -rf "$dir"; mkdir -p "$dir"
    tar -xzf "$file" -C "$dir" --strip-components=1
}

log "zlib $ZLIB_VERSION"
fetch_tarball "$S/zlib" "$ZLIB_TARBALL_URL" "$ZLIB_SHA256"
make -C "$S/zlib" -f win32/Makefile.gcc PREFIX=$HOST- -j"$JOBS" libz.a
make -C "$S/zlib" -f win32/Makefile.gcc PREFIX=$HOST- SHARED_MODE=0 \
    BINARY_PATH="$P/bin" INCLUDE_PATH="$P/include" LIBRARY_PATH="$P/lib" install
endlog

log "x264 ${X264_COMMIT:0:12}"
fetch_git "$S/x264" "$X264_URL" "$X264_REF" "$X264_COMMIT"
(cd "$S/x264" && ./configure --host=$HOST --cross-prefix=$HOST- --prefix="$P" \
    --enable-static --disable-cli --disable-opencl --enable-strip --bit-depth=all --chroma-format=all \
    && make -j"$JOBS" && make install)
endlog

log "libvpx $LIBVPX_REF"
fetch_git "$S/libvpx" "$LIBVPX_URL" "$LIBVPX_REF" "$LIBVPX_COMMIT"
(cd "$S/libvpx" && CROSS=$HOST- ./configure --target=x86_64-win64-gcc --prefix="$P" --as=nasm \
    --enable-static --disable-shared --enable-vp8 --enable-vp9 --enable-vp9-highbitdepth \
    --enable-runtime-cpu-detect --disable-examples --disable-tools --disable-docs --disable-unit-tests \
    && make -j"$JOBS" && make install)
endlog

log "opus $OPUS_VERSION"
fetch_tarball "$S/opus" "$OPUS_TARBALL_URL" "$OPUS_SHA256"
(cd "$S/opus" && ./configure --host=$HOST --prefix="$P" --enable-static --disable-shared \
    --disable-doc --disable-extra-programs --disable-hardening --disable-stack-protector \
    && make -j"$JOBS" && make install)
endlog

log "dav1d $DAV1D_REF"
fetch_git "$S/dav1d" "$DAV1D_URL" "$DAV1D_REF" "$DAV1D_COMMIT"
cat > "$W/meson-cross.txt" <<EOF
[binaries]
c = '$HOST-gcc'
cpp = '$HOST-g++'
ar = '$HOST-ar'
strip = '$HOST-strip'
windres = '$HOST-windres'
pkg-config = 'pkg-config'

[host_machine]
system = 'windows'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'
EOF
meson setup "$W/dav1d-build" "$S/dav1d" --cross-file="$W/meson-cross.txt" --prefix="$P" --libdir=lib \
    --buildtype=release --default-library=static -Denable_tools=false -Denable_tests=false -Denable_examples=false
ninja -C "$W/dav1d-build" install
endlog

log "FFmpeg $FFMPEG_REF"
fetch_git "$S/ffmpeg" "$FFMPEG_URL" "$FFMPEG_REF" "$FFMPEG_COMMIT"
mkdir -p "$W/ffmpeg-build"
(cd "$W/ffmpeg-build" && "$S/ffmpeg/configure" \
    --prefix="$W/ffmpeg-install" \
    --arch=x86_64 --target-os=mingw32 --cross-prefix=$HOST- --enable-cross-compile \
    --pkg-config=pkg-config --pkg-config-flags=--static \
    --extra-version=videosport \
    --enable-gpl \
    --disable-autodetect --enable-w32threads \
    --enable-zlib --enable-libx264 --enable-libvpx --enable-libopus --enable-libdav1d \
    --disable-network --disable-ffplay --disable-doc --disable-debug \
    --enable-static --disable-shared \
    --extra-cflags="-I$P/include" --extra-ldflags="-L$P/lib -static -static-libgcc" \
    || { tail -n 80 ffbuild/config.log; exit 1; })
make -C "$W/ffmpeg-build" -j"$JOBS"
make -C "$W/ffmpeg-build" install
endlog

log "package $NAME"
PKG="$OUT/package/$NAME"
rm -rf "$PKG"; mkdir -p "$PKG/licenses"
cp "$W/ffmpeg-install/bin/ffmpeg.exe" "$W/ffmpeg-install/bin/ffprobe.exe" "$PKG/"
$HOST-strip "$PKG/ffmpeg.exe" "$PKG/ffprobe.exe"
echo "--- DLL imports (must be Windows system DLLs only) ---"
for exe in "$PKG"/*.exe; do
    $HOST-objdump -p "$exe" | awk '/DLL Name:/{print $3}' | sort -u | tee "$W/imports-$(basename "$exe").txt"
    if grep -viE '^(kernel32|user32|gdi32|advapi32|avicap32|shell32|ole32|oleaut32|bcrypt|msvcrt|ws2_32|secur32|psapi|shlwapi|ucrtbase|api-ms-win-.*)\.dll$' \
        "$W/imports-$(basename "$exe").txt"; then echo "ERROR: unexpected DLL dependency in $exe"; exit 1; fi
done
cp "$S/ffmpeg/COPYING.GPLv2" "$PKG/licenses/FFmpeg-COPYING.GPLv2.txt"
cp "$S/ffmpeg/LICENSE.md"    "$PKG/licenses/FFmpeg-LICENSE.md"
cp "$S/x264/COPYING"         "$PKG/licenses/x264-COPYING.txt"
cp "$S/libvpx/LICENSE"       "$PKG/licenses/libvpx-LICENSE.txt"
cp "$S/libvpx/PATENTS"       "$PKG/licenses/libvpx-PATENTS.txt"
cp "$S/opus/COPYING"         "$PKG/licenses/opus-COPYING.txt"
cp "$S/dav1d/COPYING"        "$PKG/licenses/dav1d-COPYING.txt"
cp "$S/zlib/LICENSE"         "$PKG/licenses/zlib-LICENSE.txt"
cat > "$PKG/README.txt" <<EOF
videoSport FFmpeg $FFMPEG_REF (x86_64, static, GPL-2.0-or-later)

ffmpeg.exe and ffprobe.exe built by the videosport-ffmpeg.yml workflow of
https://github.com/juliobrzezinski-svg/mpv-winbuild-cmake (branch videosport-lgpl, directory videosport-ffmpeg/).
Licence: GNU GPL version 2 or later (see licenses/FFmpeg-COPYING.GPLv2.txt) because of --enable-gpl and libx264.
External libraries (statically linked): libx264, libvpx, libopus, libdav1d, zlib; their licences are in licenses/.
The complete corresponding source code (each component at the exact commit/tarball used, plus the build recipe)
is published as assets of the same GitHub Release; see SOURCES.md there.
EOF
endlog

log "sources"
git -C "$RECIPE_ROOT" archive --format=tar --prefix="videosport-ffmpeg-recipe-$(git -C "$RECIPE_ROOT" rev-parse --short=12 HEAD)/" HEAD videosport-ffmpeg .github/workflows/videosport-ffmpeg.yml \
    | gzip -9 > "$OUT/sources/src-recipe-videosport-ffmpeg-$(git -C "$RECIPE_ROOT" rev-parse --short=12 HEAD).tar.gz"
{
    echo "# Corresponding source - videoSport FFmpeg $FFMPEG_REF ($NAME)"
    echo
    echo "Recipe: https://github.com/juliobrzezinski-svg/mpv-winbuild-cmake commit $(git -C "$RECIPE_ROOT" rev-parse HEAD)"
    echo "(videosport-ffmpeg/build.sh, videosport-ffmpeg/versions.sh, .github/workflows/videosport-ffmpeg.yml)."
    echo "Toolchain: Ubuntu mingw-w64 ($($HOST-gcc --version | head -1)), $(dpkg-query -W -f='${Package} ${Version}' mingw-w64-common 2>/dev/null || true)."
    echo
    echo "| Component | Repository / URL | Version | Commit / SHA-256 | Licence | Source asset |"
    echo "|---|---|---|---|---|---|"
    echo "| FFmpeg | $FFMPEG_URL | ${FFMPEG_REF#refs/*/} | $FFMPEG_COMMIT | $FFMPEG_LICENSE | src-ffmpeg-${FFMPEG_COMMIT:0:12}.tar.gz |"
    echo "| x264 | $X264_URL | ${X264_REF#refs/*/} branch | $X264_COMMIT | $X264_LICENSE | src-x264-${X264_COMMIT:0:12}.tar.gz |"
    echo "| libvpx | $LIBVPX_URL | ${LIBVPX_REF#refs/*/} | $LIBVPX_COMMIT | $LIBVPX_LICENSE | src-libvpx-${LIBVPX_COMMIT:0:12}.tar.gz |"
    echo "| opus | $OPUS_TARBALL_URL | $OPUS_VERSION | sha256 $OPUS_SHA256 | $OPUS_LICENSE | src-$(basename "$OPUS_TARBALL_URL") |"
    echo "| dav1d | $DAV1D_URL | ${DAV1D_REF#refs/*/} | $DAV1D_COMMIT | $DAV1D_LICENSE | src-dav1d-${DAV1D_COMMIT:0:12}.tar.gz |"
    echo "| zlib | $ZLIB_TARBALL_URL | $ZLIB_VERSION | sha256 $ZLIB_SHA256 | $ZLIB_LICENSE | src-$(basename "$ZLIB_TARBALL_URL") |"
    echo
    echo "The mingw-w64 runtime (CRT and winpthreads, ZPL/MIT) and libgcc (GPL-3.0 with the GCC Runtime Library"
    echo "Exception) are linked statically from the Ubuntu toolchain packages."
    echo
    echo "## SHA-256 of the source assets"
    echo '```'
    (cd "$OUT/sources" && sha256sum src-*)
    echo '```'
} > "$OUT/sources/SOURCES.md"
endlog
echo "done: $PKG"
