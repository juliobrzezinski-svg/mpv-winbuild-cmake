ExternalProject_Add(libunibreak
    GIT_REPOSITORY https://github.com/adah1972/libunibreak.git
    # videoSport: pinned (was master) to the commit used by libmpv release videosport-lgpl-543a8c2c59-20261116
    GIT_TAG ff24f284a567a006c183b3507b6c650d6ec68b94
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} <SOURCE_DIR>/autogen.sh && CONF=1 <SOURCE_DIR>/configure
        --host=${TARGET_ARCH}
        --prefix=${MINGW_INSTALL_PREFIX}
        --disable-shared
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    BUILD_IN_SOURCE 1
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(libunibreak)
cleanup(libunibreak install)
