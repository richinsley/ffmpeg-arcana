cmake_minimum_required(VERSION 3.14)
project(Arcana)

# create ffmpeg options file
include(ffmpeg_arcana/cmake_include/create_ffmpeg_options_file.cmake)
set(FFMPEG_OPTIONS_FILE "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg_config_options.txt")
create_ffmpeg_options_file(. "${FFMPEG_OPTIONS_FILE}")

# our build options for ffmpeg
if(NOT DEFINED FFMPEG_CONFIGURE_EXTRAS)
    set(FFMPEG_CONFIGURE_EXTRAS )
endif()

# Check for FFMPEG_PKG_CONFIG_PATH. If not defined by the user,
# fall back to the PKG_CONFIG_PATH environment variable.
if(NOT DEFINED FFMPEG_PKG_CONFIG_PATH)
    set(FFMPEG_PKG_CONFIG_PATH "$ENV{PKG_CONFIG_PATH}")
endif()

# path for staged build artifacts
if(NOT DEFINED ARCANA_STAGING_DIRECTORY)
    set(ARCANA_STAGING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/staging)
endif()

# add the ffmpeg build cmake subdirectory that will create the build in the target ARCANA_STAGING_DIRECTORY
# ARCANA_SUFFIX is propagated to this scope via PARENT_SCOPE in ffmpeg.cmake
add_subdirectory(ffmpeg_arcana)

if(DEFINED NO_ARCANA_SUFFIX)
    set(ARCANA_SUFFIX )
endif()
message(STATUS "Arcana suffix: ${ARCANA_SUFFIX}")

# Validate staging directory exists at install time
install(CODE "
    if(NOT EXISTS \"${ARCANA_STAGING_DIRECTORY}/include\" OR NOT EXISTS \"${ARCANA_STAGING_DIRECTORY}/lib\")
        message(FATAL_ERROR \"Staging directory is missing expected build artifacts. Build may have failed.\n\"
            \"Expected: ${ARCANA_STAGING_DIRECTORY}/include and ${ARCANA_STAGING_DIRECTORY}/lib\")
    endif()
")

install(DIRECTORY ${ARCANA_STAGING_DIRECTORY}/include DESTINATION ${CMAKE_INSTALL_PREFIX} USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${ARCANA_STAGING_DIRECTORY}/bin DESTINATION     ${CMAKE_INSTALL_PREFIX} USE_SOURCE_PERMISSIONS)
install(DIRECTORY ${ARCANA_STAGING_DIRECTORY}/lib DESTINATION     ${CMAKE_INSTALL_PREFIX} USE_SOURCE_PERMISSIONS)
if(DEFINED INSTALL_FFMPEG_SHARED)
    install(DIRECTORY ${ARCANA_STAGING_DIRECTORY}/share DESTINATION ${CMAKE_INSTALL_PREFIX})
endif()

# perform additional post processing of installation
message(STATUS "cmake ${CMAKE_SYSTEM_NAME}")
install(
    CODE
    "execute_process(
        COMMAND
        ${CMAKE_COMMAND}
        -DARCANA_STAGING_DIRECTORY=${ARCANA_STAGING_DIRECTORY}
        -DARCANA_SUFFIX=${ARCANA_SUFFIX}
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        -DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}
        -P
        ${CMAKE_SOURCE_DIR}/ffmpeg_arcana/cmake_include/postprocess.cmake
        RESULT_VARIABLE _postprocess_result
    )
    if(NOT _postprocess_result EQUAL 0)
        message(FATAL_ERROR \"Post-processing failed with exit code: \${_postprocess_result}\")
    endif()
    "
)
