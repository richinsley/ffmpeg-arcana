# Shared list of FFmpeg library modules.
# Used by copy_headers.cmake, post_install.cmake, and postprocess.cmake.
set(FFMPEG_LIB_MODULES
    libavcodec
    libavdevice
    libavfilter
    libavformat
    libavutil
    libswresample
    libswscale
    libpostproc
)

set(FFMPEG_BIN_TARGETS
    ffmpeg
    ffprobe
    ffplay
)
