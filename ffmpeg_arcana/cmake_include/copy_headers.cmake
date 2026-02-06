cmake_minimum_required(VERSION 3.14)

include(${CMAKE_CURRENT_LIST_DIR}/ffmpeg_modules.cmake)

# We will take the headers that are installed to staging and the headers from the
# src and create a diff.  Those headers that are not installed in staging will then
# become the private headers installed to staging/libavprivate

function(copy_private avpath)
    # Define the two directories
    set(DIR1 "${STAGING}/include/${avpath}")
    set(DIR2 "${BUILD_DIR}/${avpath}")

    if(NOT EXISTS "${DIR2}")
        message(STATUS "copy_private: source directory ${DIR2} does not exist, skipping ${avpath}")
        return()
    endif()

    # Get the list of files in each directory
    file(GLOB_RECURSE FILES_DIR1 "${DIR1}/*.h")
    file(GLOB_RECURSE FILES_DIR2 "${DIR2}/*.h")

    if(NOT FILES_DIR2)
        message(STATUS "copy_private: no headers found in ${DIR2}, skipping ${avpath}")
        return()
    endif()

    # Build set of installed header relative paths for filtering
    set(INSTALLED_RELATIVE_PATHS)
    foreach(FILE ${FILES_DIR1})
        string(REPLACE "${STAGING}/include" "" RelativeFile "${FILE}")
        list(APPEND INSTALLED_RELATIVE_PATHS "${RelativeFile}")
    endforeach()

    # Copy headers that are NOT already installed (private headers)
    foreach(FILE ${FILES_DIR2})
        set(SRC_PATH "${FILE}")
        string(REPLACE "${BUILD_DIR}" "" RelativeFile "${FILE}")

        # Skip if this header was already installed to staging
        list(FIND INSTALLED_RELATIVE_PATHS "${RelativeFile}" _idx)
        if(_idx GREATER -1)
            continue()
        endif()

        string(CONCAT FullPath "${OUT}/" "${RelativeFile}")
        get_filename_component(TruePath "${FullPath}" DIRECTORY)
        file(COPY "${SRC_PATH}" DESTINATION "${TruePath}")
    endforeach()
endfunction()

# Validate required variables
foreach(_var BUILD_DIR OUT STAGING)
    if(NOT DEFINED ${_var} OR "${${_var}}" STREQUAL "")
        message(FATAL_ERROR "copy_headers.cmake: required variable ${_var} is not defined")
    endif()
endforeach()

# copy the config headers to libavprivate
file(
    COPY "${BUILD_DIR}/config.h" "${BUILD_DIR}/config_components.h"
    DESTINATION "${OUT}"
    FILES_MATCHING PATTERN *.h
)

# copy the individual private headers to libavprivate
foreach(_module ${FFMPEG_LIB_MODULES})
    copy_private(${_module})
endforeach()
copy_private(compat)
