# videoSport FFmpeg (GPL) - pinned component versions. Every component is fixed to a tag AND its commit
# (or to a release tarball AND its SHA-256), so a rebuild reproduces the same sources.
# Format per git component: <NAME>_URL, <NAME>_REF (tag or branch the commit belongs to), <NAME>_COMMIT.

FFMPEG_URL=https://github.com/FFmpeg/FFmpeg.git
FFMPEG_REF=refs/tags/n8.0.1
FFMPEG_COMMIT=894da5ca7d742e4429ffb2af534fcda0103ef593
FFMPEG_LICENSE="GPL-2.0-or-later (built with --enable-gpl)"

X264_URL=https://code.videolan.org/videolan/x264.git
X264_REF=refs/heads/stable
X264_COMMIT=b35605ace3ddf7c1a5d67a2eb553f034aef41d55
X264_LICENSE="GPL-2.0-or-later"

LIBVPX_URL=https://chromium.googlesource.com/webm/libvpx.git
LIBVPX_REF=refs/tags/v1.15.2
LIBVPX_COMMIT=d168454ecd099805c675d4a98c66f4891373302a
LIBVPX_LICENSE="BSD-3-Clause (+ PATENTS grant)"

DAV1D_URL=https://code.videolan.org/videolan/dav1d.git
DAV1D_REF=refs/tags/1.5.3
DAV1D_COMMIT=b546257f770768b2c88258c533da38b91a06f737
DAV1D_LICENSE="BSD-2-Clause"

# Release tarballs (the opus tarball already contains the DNN model data that a git checkout would download).
OPUS_VERSION=1.5.2
OPUS_TARBALL_URL=https://downloads.xiph.org/releases/opus/opus-1.5.2.tar.gz
OPUS_SHA256=65c1d2f78b9f2fb20082c38cbe47c951ad5839345876e46941612ee87f9a7ce1
OPUS_LICENSE="BSD-3-Clause"

ZLIB_VERSION=1.3.1
ZLIB_TARBALL_URL=https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
ZLIB_SHA256=9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23
ZLIB_LICENSE="Zlib"
