cmake_minimum_required(VERSION 3.10)

# path where ffmpeg private include files will be staged
set(FFMPEG_PRIVATE_INCLUDE_PATH ${ARCANA_STAGING_DIRECTORY}/include/arcana/libavprivate)

set(FFMPEG_SRC_PATH ${CMAKE_BINARY_DIR})

if(NOT DEFINED ARCANA_PATCH_VERSION)
    set(ARCANA_PATCH_VERSION 6.0)
endif()

if(NOT DEFINED FFMPEG_VERSION)
    set(FFMPEG_VERSION 6.0)
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

# Replace the ARCANA_PATCH_URL with local path
set(ARCANA_PATCH_NAME ffmpeg_arcana_patch_${ARCANA_PATCH_VERSION}.patch)
set(ARCANA_PATCH_PATH ${CMAKE_SOURCE_DIR}/patches/${ARCANA_PATCH_NAME})

get_filename_component(FFMPEG_ARCHIVE_NAME ${FFMPEG_URL} NAME)

if (NOT EXISTS ${FFMPEG_SRC_PATH}/${FFMPEG_NAME})
    file(DOWNLOAD ${FFMPEG_URL} ${FFMPEG_SRC_PATH}/${FFMPEG_ARCHIVE_NAME})
    execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xzf ${FFMPEG_SRC_PATH}/${FFMPEG_ARCHIVE_NAME}
            WORKING_DIRECTORY ${FFMPEG_SRC_PATH}
    )

    # Remove the download of patch file and use local file instead
    find_package(Patch)
    if(Patch_FOUND AND EXISTS "${ARCANA_PATCH_PATH}")
        message(STATUS "Applying Arcana patch: ${ARCANA_PATCH_PATH} to ${FFMPEG_SRC_PATH}/${FFMPEG_NAME}")
        execute_process(COMMAND ${Patch_EXECUTABLE} -ruN -p1 --input ${ARCANA_PATCH_PATH}
                            WORKING_DIRECTORY ${FFMPEG_SRC_PATH}/${FFMPEG_NAME}
                            RESULT_VARIABLE PATCH_APPLY_RESULT)
        if(NOT PATCH_APPLY_RESULT EQUAL "0")
                message(FATAL_ERROR "patch apply ${ARCANA_PATCH_PATH} to folder ${FFMPEG_SRC_PATH}/${FFMPEG_NAME} failed with ${PATCH_APPLY_RESULT}")
        endif()
    else()
        message(FATAL_ERROR "Either patch command not found or patch file ${ARCANA_PATCH_PATH} does not exist")
    endif()
endif()

file(
        COPY ${CMAKE_CURRENT_SOURCE_DIR}/cmake_include/ffmpeg_build_system.cmake
        DESTINATION ${FFMPEG_SRC_PATH}/${FFMPEG_NAME}
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)

set(NJOBS 4)

ExternalProject_Add(ffmpeg_target
        PREFIX ffmpeg_pref
        URL ${FFMPEG_SRC_PATH}/${FFMPEG_NAME}
        DOWNLOAD_NO_EXTRACT 1
        CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
            AS_FLAGS=${FFMPEG_ASM_FLAGS}
            ${CMAKE_COMMAND}
            -DSTEP=configure
            -DFFMPEG_OPTIONS_FILE=${FFMPEG_OPTIONS_FILE}
            -DPREFIX=${ARCANA_STAGING_DIRECTORY}
            -DCONFIGURE_EXTRAS=${FFMPEG_CONFIGURE_EXTRAS}
            -DARCANA_SUFFIX=${ARCANA_SUFFIX}
            -DARCANA_EXTRA_VERSION=${ARCANA_EXTRA_VERSION}
        -P ffmpeg_build_system.cmake
        BUILD_COMMAND ${CMAKE_COMMAND} -E env
            ${CMAKE_COMMAND}
            -DSTEP=build
            -NJOBS=${NJOBS}
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
            -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
            -DFFMPEG_NAME=${FFMPEG_NAME}
            -DOUT=${FFMPEG_PRIVATE_INCLUDE_PATH}
            -DSTAGING=${ARCANA_STAGING_DIRECTORY}
        -P  ${CMAKE_CURRENT_SOURCE_DIR}/cmake_include/copy_headers.cmake
        DEPENDEES install
)

ExternalProject_Get_property(ffmpeg_target SOURCE_DIR)
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

