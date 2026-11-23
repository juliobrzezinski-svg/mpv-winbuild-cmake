ExternalProject_Add(glad
    GIT_REPOSITORY https://github.com/Dav1dde/glad.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    # videoSport: pinned (was glad2) to the commit used by libmpv release videosport-lgpl-543a8c2c59-20261116
    GIT_TAG 0a7cf1af9e25e02821587bd4095807fc90b6426a
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(glad)
cleanup(glad install)
