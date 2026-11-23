ExternalProject_Add(fast_float
    GIT_REPOSITORY https://github.com/fastfloat/fast_float.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    # videoSport: pinned (was main) to the commit used by libmpv release videosport-lgpl-543a8c2c59-20261116
    GIT_TAG 8ec59686a1430867ba609c2777ca15143dd81003
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(fast_float)
cleanup(fast_float install)
