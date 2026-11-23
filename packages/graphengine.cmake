ExternalProject_Add(graphengine
    GIT_REPOSITORY https://github.com/sekrit-twc/graphengine.git
    # videoSport: pinned (was master) to the commit used by libmpv release videosport-lgpl-543a8c2c59-20261116
    GIT_TAG 91c6af4c795c5396d8b974f24b4d2e2ecca04e2d
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(graphengine)
cleanup(graphengine install)
