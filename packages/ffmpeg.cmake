ExternalProject_Add(ffmpeg
    # videoSport LGPL build: only libs needed for PLAYBACK (all BSD/MIT/ISC).
    # Removed vs upstream: openssl, libssh, libsrt, x264, x265, rubberband, vapoursynth, dvd/bluray, lame, ...
    DEPENDS
        nvcodec-headers
        opus
        vorbis
        dav1d
        zlib
    GIT_REPOSITORY https://github.com/FFmpeg/FFmpeg.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !tests/ref/fate"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 <SOURCE_DIR>/configure
        --cross-prefix=${TARGET_ARCH}-
        --prefix=${MINGW_INSTALL_PREFIX}
        --arch=${TARGET_CPU}
        --target-os=mingw32
        --pkg-config-flags=--static
        --enable-cross-compile
        --enable-runtime-cpudetect
        # videoSport LGPL build: NO --enable-gpl, NO --enable-version3, NO --enable-nonfree
        # (result is LGPL-2.1+). Only BSD/MIT/ISC external libs are enabled.
        --enable-libopus
        --enable-libvorbis
        --enable-libdav1d
        --enable-cuda-llvm
        --enable-cuvid
        --enable-nvdec
        --disable-nvenc
        --disable-amf
        --disable-vaapi
        --disable-vdpau
        --disable-videotoolbox
        --disable-network
        --disable-autodetect
        --enable-d3d11va
        --enable-dxva2
        --enable-zlib
        --disable-doc
        --disable-ffplay
        --disable-ffprobe
        ${ffmpeg_lto}
        --extra-cflags='-Wno-error=int-conversion'
        "--extra-libs='${ffmpeg_extra_libs}'" # -lstdc++ / -lc++ needs by libjxl and shaderc
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(ffmpeg)
cleanup(ffmpeg install)
