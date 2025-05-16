cmake_minimum_required(VERSION 3.10)

# We will take the headers that are installed to staging and the headers from the
# src and create a diff.  Those headers that are not installed in staging will then
# become the private headers installed to staging/libavprivate

function(copy_private avpath)
        # Define the two directories
        set(DIR1 ${STAGING}/include/${avpath})
        set(DIR2 ${BUILD_DIR}/${avpath})

        # Get the list of files in each directory
        file(GLOB_RECURSE FILES_DIR1 "${DIR1}/*.h")
        file(GLOB_RECURSE FILES_DIR2 "${DIR2}/*.h")

        # build up directory tree of absolute paths for each source headers file
        foreach(FILE ${FILES_DIR1})
                # truncate staging path and prepend build dir path
                string(REPLACE "${STAGING}/include" "" RelativeFile ${FILE})
                string(CONCAT TruePath "${BUILD_DIR}" ${RelativeFile})
                list(REMOVE_ITEM FILES_DIR2 ${TruePath})
        endforeach()

        # walk the directory tree and copy the headers to staging
        foreach(FILE ${FILES_DIR2})
                set(SRC_PATH ${FILE})
                string(REPLACE "${BUILD_DIR}" "" RelativeFile ${FILE})
                string(CONCAT FullPath ${OUT}/ ${RelativeFile})
                get_filename_component(TruePath ${FullPath} DIRECTORY)
                file(
                        COPY ${SRC_PATH}
                        DESTINATION ${TruePath}
                )
        endforeach()
endfunction()

# copy the config headers to libavprivate
file(
        COPY ${BUILD_DIR}/config.h ${BUILD_DIR}/config_components.h
        DESTINATION ${OUT}
        FILES_MATCHING PATTERN *.h
)

# copy the individual private headers to libavprivate
copy_private(libavcodec)
copy_private(libavdevice)
copy_private(libavfilter)
copy_private(libavformat)
copy_private(libavutil)
copy_private(libswresample)
copy_private(libswscale)
copy_private(libpostproc)
copy_private(compat)

