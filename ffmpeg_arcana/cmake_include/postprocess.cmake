cmake_minimum_required(VERSION 3.10)

function(adjust_rpath type obj)
    # we want to handle dylibs and exe
    if (${type} STREQUAL "lib")
        set(TARGET_OBJ "${CMAKE_INSTALL_PREFIX}/${type}/${obj}${ARCANA_SUFFIX}.dylib")
    else()
        set(TARGET_OBJ "${CMAKE_INSTALL_PREFIX}/${type}/${obj}${ARCANA_SUFFIX}")
    endif()

    if(EXISTS ${TARGET_OBJ})
        message(STATUS "processing rpath for ${TARGET_OBJ}")
        execute_process (
            COMMAND bash -c "otool -L ${TARGET_OBJ} | grep ${ARCANA_STAGING_DIRECTORY}/lib"
            OUTPUT_VARIABLE OTOOLOUT
        )

        # Replace the contents within the parentheses (including the parentheses themselves) with an empty string, using a non-greedy regex
        string(REGEX REPLACE "\\([^)]*\\)" "" no_paren_str "${OTOOLOUT}")

        # Replace newline characters with semicolons
        string(REPLACE "\n" ";" list_str "${no_paren_str}")

        # Create a list from the string
        string(STRIP "${list_str}" list_str) # Remove any leading/trailing whitespace
        string(REPLACE ";;" ";" list_str "${list_str}") # Replace double semicolons with a single one
        list(REMOVE_ITEM list_str "") # Remove any empty items
        string(REGEX MATCHALL "[^;]+" result_list "${list_str}") # Create a list from the string using semicolons as delimiters

        # process each item with "install_name_tool -change"
        foreach(item IN LISTS result_list)
            # get the component
            get_filename_component(filename "${item}" NAME)
            set(NEW_TARGET "${CMAKE_INSTALL_PREFIX}/lib/${filename}")

            # if this is a dylib, and the component is equal to "obj", use "install_name_tool -id" instead if "install_name_tool -change"
            string(LENGTH "${obj}" length_of_obj)
            string(SUBSTRING "${filename}" 0 ${length_of_obj} filename_sub)
            if(obj STREQUAL filename_sub)
                execute_process (
                    COMMAND bash -c "install_name_tool -id ${NEW_TARGET} ${TARGET_OBJ}"
                )
            else()
                execute_process (
                    COMMAND bash -c "install_name_tool -change ${item} ${NEW_TARGET} ${TARGET_OBJ}"
                )
            endif()
        endforeach()

        # handle relative path for bins
        # https://stackoverflow.com/questions/32524673/install-name-tool-does-not-make-any-changes
    else()
        message(STATUS "${TARGET_OBJ} not found for rpath adjustment")
    endif()
endfunction()

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    message(STATUS "adjusting rpath for macos dylibs")
    adjust_rpath(lib libavcodec)
    adjust_rpath(lib libavdevice)
    adjust_rpath(lib libavfilter)
    adjust_rpath(lib libavformat)
    adjust_rpath(lib libavutil)
    adjust_rpath(lib libswresample)
    adjust_rpath(lib libswscale)
    adjust_rpath(lib libpostproc)

    adjust_rpath(bin ffmpeg)
    adjust_rpath(bin ffprobe)
    adjust_rpath(bin ffplay)
endif()