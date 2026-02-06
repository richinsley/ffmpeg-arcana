cmake_minimum_required(VERSION 3.14)

project(test_arcana_plugs LANGUAGES CXX C)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Validate ARCANA_PREFIX is set
if(NOT DEFINED ARCANA_PREFIX OR "${ARCANA_PREFIX}" STREQUAL "")
    message(FATAL_ERROR "ARCANA_PREFIX must be set to the Arcana FFmpeg install directory.\n"
        "Usage: cmake -DARCANA_PREFIX=/path/to/arcana_install ..")
endif()

if(NOT EXISTS "${ARCANA_PREFIX}/include")
    message(FATAL_ERROR "ARCANA_PREFIX directory '${ARCANA_PREFIX}' does not contain an include/ directory.\n"
        "Has FFmpeg Arcana been built and installed?")
endif()

add_library(test_arcana_plugs SHARED
    # test_proto.c
    test_mux.c
    # nut.c
    test_enc.c
    test_filter.c
    arcana_loader.c
)

# Use target-based include directories
target_include_directories(test_arcana_plugs PRIVATE
    "${ARCANA_PREFIX}/include"
    "${ARCANA_PREFIX}/include/arcana/libavprivate"
)

# Use target-based link directories
target_link_directories(test_arcana_plugs PRIVATE
    "${ARCANA_PREFIX}/lib"
)

# Use target_compile_definitions instead of manipulating CMAKE_CXX_FLAGS
target_compile_definitions(test_arcana_plugs PRIVATE __STDC_CONSTANT_MACROS)

# Define FFMPEG_LIBS explicitly if not provided by the user
if(NOT DEFINED FFMPEG_LIBS)
    set(FFMPEG_LIBS avfilter avformat avcodec avutil swresample swscale)
endif()

target_link_libraries(test_arcana_plugs PRIVATE
    ${FFMPEG_LIBS}
)

install(TARGETS test_arcana_plugs
    LIBRARY DESTINATION "${ARCANA_PREFIX}/lib/testplugs"
    ARCHIVE DESTINATION "${ARCANA_PREFIX}/lib/testplugs"
    RUNTIME DESTINATION "${ARCANA_PREFIX}/bin"
)
