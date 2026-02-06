cmake_minimum_required(VERSION 3.14)

include(${CMAKE_CURRENT_LIST_DIR}/ffmpeg_modules.cmake)

function(adjust_rpath type obj)
    # we want to handle dylibs and exe
    if("${type}" STREQUAL "lib")
        set(TARGET_OBJ "${CMAKE_INSTALL_PREFIX}/${type}/${obj}${ARCANA_SUFFIX}.dylib")
    else()
        set(TARGET_OBJ "${CMAKE_INSTALL_PREFIX}/${type}/${obj}${ARCANA_SUFFIX}")
    endif()

    if(EXISTS "${TARGET_OBJ}")
        message(STATUS "processing rpath for ${TARGET_OBJ}")
        execute_process(
            COMMAND otool -L "${TARGET_OBJ}"
            OUTPUT_VARIABLE OTOOL_FULL_OUTPUT
            RESULT_VARIABLE OTOOL_RESULT
        )
        if(NOT OTOOL_RESULT EQUAL 0)
            message(WARNING "otool failed on ${TARGET_OBJ}")
            return()
        endif()

        # Filter to only lines referencing the staging directory
        string(REPLACE "\n" ";" OTOOL_LINES "${OTOOL_FULL_OUTPUT}")
        set(MATCHING_LIBS)
        foreach(_line ${OTOOL_LINES})
            string(FIND "${_line}" "${ARCANA_STAGING_DIRECTORY}/lib" _found)
            if(_found GREATER -1)
                # Extract the library path (everything before the parenthesized info)
                string(REGEX REPLACE "\\(.*\\)" "" _clean "${_line}")
                string(STRIP "${_clean}" _clean)
                if(NOT "${_clean}" STREQUAL "")
                    list(APPEND MATCHING_LIBS "${_clean}")
                endif()
            endif()
        endforeach()

        # process each item with "install_name_tool -change"
        foreach(item IN LISTS MATCHING_LIBS)
            get_filename_component(filename "${item}" NAME)
            set(NEW_TARGET "${CMAKE_INSTALL_PREFIX}/lib/${filename}")

            # if this is a dylib and the filename starts with "obj", use -id instead of -change
            string(LENGTH "${obj}" length_of_obj)
            string(LENGTH "${filename}" length_of_filename)
            if(length_of_filename GREATER_EQUAL length_of_obj)
                string(SUBSTRING "${filename}" 0 ${length_of_obj} filename_sub)
            else()
                set(filename_sub "")
            endif()

            if("${obj}" STREQUAL "${filename_sub}")
                execute_process(
                    COMMAND install_name_tool -id "${NEW_TARGET}" "${TARGET_OBJ}"
                    RESULT_VARIABLE _result
                )
                if(NOT _result EQUAL 0)
                    message(WARNING "install_name_tool -id failed on ${TARGET_OBJ}")
                endif()
            else()
                execute_process(
                    COMMAND install_name_tool -change "${item}" "${NEW_TARGET}" "${TARGET_OBJ}"
                    RESULT_VARIABLE _result
                )
                if(NOT _result EQUAL 0)
                    message(WARNING "install_name_tool -change failed on ${TARGET_OBJ}")
                endif()
            endif()
        endforeach()
    else()
        message(STATUS "${TARGET_OBJ} not found for rpath adjustment")
    endif()
endfunction()

if("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
    message(STATUS "adjusting rpath for macOS dylibs")
    foreach(_module ${FFMPEG_LIB_MODULES})
        adjust_rpath(lib ${_module})
    endforeach()
    foreach(_bin ${FFMPEG_BIN_TARGETS})
        adjust_rpath(bin ${_bin})
    endforeach()
else()
    message(STATUS "no rpath adjustment needed on ${CMAKE_SYSTEM_NAME}")
endif()
