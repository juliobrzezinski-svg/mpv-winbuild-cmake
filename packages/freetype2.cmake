ExternalProject_Add(freetype2
    DEPENDS
        libpng
        zlib
        brotli
    GIT_REPOSITORY https://github.com/freetype/freetype.git
    # videoSport: pinned (was master) to the commit used by libmpv release videosport-lgpl-543a8c2c59-20261116
    GIT_TAG dbb00e529e69a2be629a9ef98498e4f9b188aab1
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 meson setup <BINARY_DIR> <SOURCE_DIR>
        --prefix=${MINGW_INSTALL_PREFIX}
        --libdir=${MINGW_INSTALL_PREFIX}/lib
        --cross-file=${MESON_CROSS}
        --buildtype=release
        --default-library=static
        -Dharfbuzz=disabled
        -Dtests=disabled
        -Dbrotli=enabled
        -Dzlib=enabled
        -Dpng=enabled
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(freetype2)
force_meson_configure(freetype2)
cleanup(freetype2 install)
