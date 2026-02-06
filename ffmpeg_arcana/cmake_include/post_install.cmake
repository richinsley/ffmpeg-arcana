cmake_minimum_required(VERSION 3.14)

include(${CMAKE_CURRENT_LIST_DIR}/ffmpeg_modules.cmake)

function(adjust_pkgconf pkgpc)
    set(PC_PATH "${ARCANA_STAGING_DIRECTORY}/lib/pkgconfig/${pkgpc}${ARCANA_SUFFIX}.pc")
    if(EXISTS "${PC_PATH}")
        file(READ "${PC_PATH}" pcfiledata)
        string(REPLACE "${ARCANA_STAGING_DIRECTORY}" "${CMAKE_INSTALL_PREFIX}" MODIFIED_PC "${pcfiledata}")
        # append " -I${includedir}/libavprivate" to "Cflags:" line using regex for flexibility
        string(REGEX REPLACE "(Cflags:[^\n]*)" "\\1 -I\${includedir}/libavprivate" FINAL "${MODIFIED_PC}")
        file(WRITE "${PC_PATH}" "${FINAL}")
        message(STATUS "adjusted paths for ${PC_PATH}")
    else()
        message(WARNING "package config file ${PC_PATH} not found")
    endif()
endfunction()

foreach(_module ${FFMPEG_LIB_MODULES})
    adjust_pkgconf(${_module})
endforeach()
