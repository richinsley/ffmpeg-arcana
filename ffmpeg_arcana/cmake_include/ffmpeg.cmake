cmake_minimum_required(VERSION 3.14)

# path where ffmpeg private include files will be staged
set(FFMPEG_PRIVATE_INCLUDE_PATH ${ARCANA_STAGING_DIRECTORY}/include/arcana/libavprivate)

set(FFMPEG_SRC_PATH ${CMAKE_BINARY_DIR})

if(NOT DEFINED ARCANA_PATCH_VERSION)
    set(ARCANA_PATCH_VERSION 8.0)
endif()

if(NOT DEFINED FFMPEG_VERSION)
    set(FFMPEG_VERSION 8.0)
endif()

set(FFMPEG_NAME ffmpeg-${FFMPEG_VERSION})
set(FFMPEG_URL https://ffmpeg.org/releases/${FFMPEG_NAME}.tar.bz2)

if(NOT DEFINED NO_ARCANA_SUFFIX)
    if(NOT DEFINED ARCANA_SUFFIX)
        set(ARCANA_SUFFIX _arcana)
    endif()

    if(NOT DEFINED ARCANA_EXTRA_VERSION)
        set(ARCANA_EXTRA_VERSION _arcana)
    endif()
else()
    message(STATUS "Skipping Arcana suffix")
    set(ARCANA_SUFFIX )
    set(ARCANA_EXTRA_VERSION )
endif()

# Propagate ARCANA_SUFFIX to parent scope so root CMakeLists.txt can access it
set(ARCANA_SUFFIX "${ARCANA_SUFFIX}" PARENT_SCOPE)

# Replace the ARCANA_PATCH_URL with local path
set(ARCANA_PATCH_NAME ffmpeg_arcana_patch_${ARCANA_PATCH_VERSION}.patch)
set(ARCANA_PATCH_PATH ${CMAKE_SOURCE_DIR}/patches/${ARCANA_PATCH_NAME})

# Validate that the patch file exists before proceeding
if(NOT EXISTS "${ARCANA_PATCH_PATH}")
    message(FATAL_ERROR "Arcana patch file not found: ${ARCANA_PATCH_PATH}\n"
        "Available versions can be found in ${CMAKE_SOURCE_DIR}/patches/")
endif()

get_filename_component(FFMPEG_ARCHIVE_NAME ${FFMPEG_URL} NAME)

# Sentinel file to track that patching was already applied
set(ARCANA_PATCH_SENTINEL "${FFMPEG_SRC_PATH}/${FFMPEG_NAME}/.arcana_patched")

if(NOT EXISTS "${FFMPEG_SRC_PATH}/${FFMPEG_NAME}")
    file(DOWNLOAD ${FFMPEG_URL} "${FFMPEG_SRC_PATH}/${FFMPEG_ARCHIVE_NAME}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xf "${FFMPEG_SRC_PATH}/${FFMPEG_ARCHIVE_NAME}"
        WORKING_DIRECTORY "${FFMPEG_SRC_PATH}"
        RESULT_VARIABLE TAR_RESULT
    )
    if(NOT TAR_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to extract ${FFMPEG_ARCHIVE_NAME}")
    endif()
endif()

# Apply patches only if not already applied (sentinel file check)
if(NOT EXISTS "${ARCANA_PATCH_SENTINEL}")
    find_package(Patch)
    if(Patch_FOUND AND EXISTS "${ARCANA_PATCH_PATH}")
        message(STATUS "Applying Arcana patch: ${ARCANA_PATCH_PATH} to ${FFMPEG_SRC_PATH}/${FFMPEG_NAME}")
        execute_process(COMMAND ${Patch_EXECUTABLE} -ruN -p1 --input "${ARCANA_PATCH_PATH}"
                            WORKING_DIRECTORY "${FFMPEG_SRC_PATH}/${FFMPEG_NAME}"
                            RESULT_VARIABLE PATCH_APPLY_RESULT)
        if(NOT PATCH_APPLY_RESULT EQUAL 0)
            message(FATAL_ERROR "patch apply ${ARCANA_PATCH_PATH} to folder ${FFMPEG_SRC_PATH}/${FFMPEG_NAME} failed with ${PATCH_APPLY_RESULT}")
        endif()
    else()
        message(FATAL_ERROR "Patch command not found (install 'patch' utility) or patch file ${ARCANA_PATCH_PATH} does not exist")
    endif()

    if(ADDITIONAL_PATCHES AND EXISTS "${ADDITIONAL_PATCHES}")
        file(GLOB patch_files "${ADDITIONAL_PATCHES}/*.patch")
        foreach(patch_file ${patch_files})
            message(STATUS "Applying additional patch: ${patch_file}")
            execute_process(COMMAND ${Patch_EXECUTABLE} -ruN -p1 --input "${patch_file}"
                            WORKING_DIRECTORY "${FFMPEG_SRC_PATH}/${FFMPEG_NAME}"
                            RESULT_VARIABLE ADDITIONAL_PATCH_APPLY_RESULT)
            if(NOT ADDITIONAL_PATCH_APPLY_RESULT EQUAL 0)
                message(FATAL_ERROR "patch apply ${patch_file} to folder ${FFMPEG_SRC_PATH}/${FFMPEG_NAME} failed with ${ADDITIONAL_PATCH_APPLY_RESULT}")
            endif()
        endforeach()
    endif()

    # Write sentinel to prevent double-patching on re-configure
    file(WRITE "${ARCANA_PATCH_SENTINEL}" "patched with ${ARCANA_PATCH_NAME}\n")
endif()

file(
    COPY ${CMAKE_CURRENT_SOURCE_DIR}/cmake_include/ffmpeg_build_system.cmake
    DESTINATION "${FFMPEG_SRC_PATH}/${FFMPEG_NAME}"
    FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)

# Auto-detect CPU count with user override
if(NOT DEFINED NJOBS)
    cmake_host_system_information(RESULT NJOBS QUERY NUMBER_OF_LOGICAL_CORES)
    message(STATUS "Auto-detected ${NJOBS} logical cores for parallel build")
endif()

ExternalProject_Add(ffmpeg_target
        PREFIX ffmpeg_pref
        URL "${FFMPEG_SRC_PATH}/${FFMPEG_NAME}"
        DOWNLOAD_NO_EXTRACT 1
        CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
            PKG_CONFIG_PATH=${FFMPEG_PKG_CONFIG_PATH}
            AS_FLAGS=${FFMPEG_ASM_FLAGS}
            ${CMAKE_COMMAND}
            -DSTEP=configure
            -DFFMPEG_OPTIONS_FILE=${FFMPEG_OPTIONS_FILE}
            -DPREFIX=${ARCANA_STAGING_DIRECTORY}
            -DCONFIGURE_EXTRAS=${FFMPEG_CONFIGURE_EXTRAS}
            -DARCANA_SUFFIX=${ARCANA_SUFFIX}
            -DARCANA_EXTRA_VERSION=${ARCANA_EXTRA_VERSION}
            -DFFMPEG_PKG_CONFIG_PATH=${FFMPEG_PKG_CONFIG_PATH}
        -P ffmpeg_build_system.cmake
        BUILD_COMMAND ${CMAKE_COMMAND} -E env
            ${CMAKE_COMMAND}
            -DSTEP=build
            -DNJOBS=${NJOBS}
        -P ffmpeg_build_system.cmake
        BUILD_IN_SOURCE 1
        INSTALL_COMMAND ${CMAKE_COMMAND} -E env
            ${CMAKE_COMMAND}
            -DSTEP=install
        -P ffmpeg_build_system.cmake
        STEP_TARGETS copy_headers
        LOG_CONFIGURE 1
        LOG_BUILD 1
        LOG_INSTALL 1
        DEPENDS ${FFMPEG_DEPENDS}
)

ExternalProject_Get_property(ffmpeg_target SOURCE_DIR)

# add the copy_headers step to the ffmpeg_target external project
ExternalProject_Add_Step(
        ffmpeg_target
        copy_headers
        COMMAND ${CMAKE_COMMAND}
            -DBUILD_DIR=${SOURCE_DIR}
            -DOUT=${FFMPEG_PRIVATE_INCLUDE_PATH}
            -DSTAGING=${ARCANA_STAGING_DIRECTORY}
        -P  ${CMAKE_CURRENT_SOURCE_DIR}/cmake_include/copy_headers.cmake
        DEPENDEES install
)

# add the adjust_pkgconfig step to the ffmpeg_target external project
ExternalProject_Add_Step(
        ffmpeg_target
        adjust_pkgconfig
        COMMAND ${CMAKE_COMMAND}
            -DARCANA_SUFFIX=${ARCANA_SUFFIX}
            -DARCANA_STAGING_DIRECTORY=${ARCANA_STAGING_DIRECTORY}
            -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
        -P  ${CMAKE_CURRENT_SOURCE_DIR}/cmake_include/post_install.cmake
        DEPENDEES install
)
