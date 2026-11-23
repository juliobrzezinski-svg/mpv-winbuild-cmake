ExternalProject_Add(dav1d
    DEPENDS
        xxhash
    GIT_REPOSITORY https://code.videolan.org/videolan/dav1d.git
    # videoSport: pinned (was master) to the commit used by libmpv release videosport-lgpl-543a8c2c59-20261116
    GIT_TAG 9a03b544c0ad0edcf881441663b4f5492b819cde
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 meson setup <BINARY_DIR> <SOURCE_DIR>
        --prefix=${MINGW_INSTALL_PREFIX}
        --libdir=${MINGW_INSTALL_PREFIX}/lib
        --cross-file=${MESON_CROSS}
        --buildtype=release
        --default-library=static
        -Denable_tools=false
        -Denable_tests=false
        -Dxxhash_muxer=enabled
    BUILD_COMMAND ${EXEC} ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} ninja -C <BINARY_DIR> install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(dav1d)
force_meson_configure(dav1d)
cleanup(dav1d install)
