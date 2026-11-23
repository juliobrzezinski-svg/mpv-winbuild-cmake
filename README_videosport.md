# videoSport LGPL libmpv (fork of shinchiro/mpv-winbuild-cmake)

Purpose: build our own `libmpv-2.dll` as **LGPL** (instead of the GPL builds published upstream) so videoSport can
bundle it. Branch `videosport-lgpl`; diffs vs upstream `master` are confined to `packages/mpv.cmake`,
`packages/ffmpeg.cmake` and the new workflow, so upstream stays mergeable.

## Build
GitHub Actions -> "videosport libmpv lgpl" (`.github/workflows/videosport-libmpv.yml`, workflow_dispatch, ref
`videosport-lgpl`). Target: plain `x86_64` (GCC_ARCH=x86-64, no AVX2 requirement), gcc toolchain. The job builds
libmpv, checks the licence strings, uploads the artifact `libmpv-lgpl-x86_64` and (input `release`, default true)
creates a Release `videosport-lgpl-<mpv-short-sha>-<yyyymmdd>` with the `.7z` and `SHA256SUMS.txt`. The first run
builds the cross toolchain (cached afterwards).

Rebuild: `gh workflow run videosport-libmpv.yml --ref videosport-lgpl`.

## Options
mpv (meson): `-Dgpl=false`, libmpv=true; lua, javascript, sdl2-gamepad, libarchive, libbluray, dvdnav, dvda, cdda,
rubberband, openal, vapoursynth, subrandr, sixel, libcurl, pdf-build, manpage-build = disabled. Kept: gl + ANGLE,
d3d11, vulkan, libplacebo, shaderc, spirv-cross, libass, lcms2, uchardet, zimg, jpeg, iconv, d3d11va/dxva2 and
cuda hwaccel (ffnvcodec headers, MIT).

FFmpeg (built inside): no `--enable-gpl`, no `--enable-version3`, no `--enable-nonfree` (=> LGPL-2.1+);
`--disable-autodetect`, `--disable-network`; external libs only libopus, libvorbis, libdav1d, zlib; nvdec/cuvid,
d3d11va, dxva2 enabled; nvenc/amf/vaapi disabled. Native decoders cover h264, hevc, vp8/vp9, av1 (via dav1d),
aac, mp3, etc. Removed: x264, x265, rubberband, vapoursynth, dvd/bluray, openssl, ssh, srt, lame, ...

## Licence
mpv with `-Dgpl=false`: LGPL-2.1-or-later. FFmpeg without gpl/version3: LGPL-2.1-or-later. Static third-party
libs are LGPL/BSD/MIT/ISC/zlib/MPL/Apache-2.0 (libplacebo LGPL-2.1+, libass ISC, fribidi LGPL-2.1, libiconv
LGPL-2.1, uchardet MPL, shaderc/spirv-cross Apache-2.0, dav1d BSD-2). The DLL must be shipped as a separate
dynamic library (replaceable by the user) and the corresponding source (this fork + upstream commits) must be
available on distribution.

## Verify
`strings -a libmpv-2.dll | grep -- '-Dgpl=false'` must match; `strings -a libmpv-2.dll | grep -- '--enable-gpl'` must
NOT match. The package also contains `mpv-configuration.txt` (extracted strings).

## Pinned sources (corresponding source of release videosport-lgpl-543a8c2c59-20261116)
Upstream recipes follow git HEAD. Since 2026-11-23 every package that ends up in `libmpv-2.dll` is pinned with
`GIT_TAG <commit>` (and `GIT_REMOTE_NAME` removed, which `force_rebuild_git` treats as "fixed commit") to the
commit used by run 43909773666 (recipe commit `babc0c4`), which produced the release
`videosport-lgpl-543a8c2c59-20261116`. `toolchain/mingw-w64.cmake` is pinned too (the toolchain of that run came
from the cache built by run 43896080503). libiconv, opus-dnn, gcc and binutils were already fixed tarballs.

How the commits were determined (full table with method per package in `SOURCES.md` / `sources.json`, assets of
that release, together with one source archive per package and the recipe archive):
- read from version strings embedded in the DLL (mpv, FFmpeg, libass, libplacebo, libopus, dav1d, SPIRV-Cross),
  or from the package name in the run log (mpv `git-543a8c2c59`);
- the rest reconstructed as `git rev-list -1 --first-parent --before=2026-11-16T16:49:29Z origin/<branch>`
  (the `ninja update` step fetched and reset every package to its upstream branch at about that time;
  `<branch>` is the recipe's `GIT_TAG`, or `master` when none, which is CMake's ExternalProject default).
  For dav1d the date method would have picked a commit pushed later, so the embedded string wins.

Not pinned: the build container `ghcr.io/shinchiro/archlinux:latest` (the digest used on 2026-11-16 is no longer
in the registry) and the other packages of the upstream recipe that libmpv does not use. A rebuild therefore
reproduces the same sources, not necessarily a bit-identical DLL. To move to newer upstream code, update the
`GIT_TAG` lines and publish the matching sources with the new release.

# videoSport static GPL FFmpeg (videosport-ffmpeg/)
Separate from libmpv. `videosport-ffmpeg/build.sh` cross-compiles on Ubuntu (distro mingw-w64) a fully static
`ffmpeg.exe` + `ffprobe.exe` (no DLLs) of FFmpeg n8.0.1 with `--enable-gpl` and only libx264, libvpx, libopus,
libdav1d and zlib, all pinned in `videosport-ffmpeg/versions.sh` (commit or tarball SHA-256). Every native
decoder/encoder/demuxer/muxer/parser/filter and the file protocols are kept; network, ffplay, docs and
autodetection are off (`--enable-w32threads` explicitly, since `--disable-autodetect` drops it).
`videosport-ffmpeg/check.sh` checks the binary on Windows (encoders libx264/aac/libvpx-vp9/libopus, decoders
hevc/h264/aac/libdav1d, filters, concat demuxer, test encodes).

Workflow `videosport-ffmpeg.yml`: on push to the recipe it only builds and checks; `workflow_dispatch`
(`gh workflow run videosport-ffmpeg.yml --ref videosport-lgpl`) also creates the Release
`videosport-ffmpeg-n8.0.1-<yyyymmdd>` with the .zip, its SHA-256, the `-version/-buildconf/-encoders/-decoders/
-filters` outputs, COPYING.GPLv2, one source archive per component, the recipe archive and `SOURCES.md`.
Licence of the result: GPL-2.0-or-later.
