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
