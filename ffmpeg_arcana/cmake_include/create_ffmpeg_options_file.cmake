function(create_ffmpeg_options_file dir outfile)
    # iterate over the cmake cache of variables and look for ones that start with "FFOPT_"
    get_property(_variableNames DIRECTORY ${dir} PROPERTY VARIABLES)
    list(SORT _variableNames)
    list(REMOVE_DUPLICATES _variableNames)
    file(WRITE "${outfile}" "")
    foreach(_variableName ${_variableNames})
        # if the variable starts with "FFOPT_", convert to ffmpeg's ./configure options
        if(_variableName MATCHES "^FFOPT_")
            get_directory_property(_variableValue DIRECTORY ${dir} DEFINITION ${_variableName})

            # remove the FFOPT_ prefix
            string(REPLACE "FFOPT_" "" _optionName "${_variableName}")

            # replace '_' with '-' and make all lower case and prepend '--'
            string(REPLACE "_" "-" _optionName "${_optionName}")
            string(TOLOWER "${_optionName}" _optionName)
            string(PREPEND _optionName "--")

            # is it a boolean flag? if so, skip it if it is 'false'
            string(TOLOWER "${_variableValue}" _vtolower)
            if(_vtolower STREQUAL "true" OR _vtolower STREQUAL "false"
                OR _vtolower STREQUAL "on" OR _vtolower STREQUAL "off"
                OR _vtolower STREQUAL "yes" OR _vtolower STREQUAL "no")
                if(_vtolower STREQUAL "true" OR _vtolower STREQUAL "on" OR _vtolower STREQUAL "yes")
                    file(APPEND "${outfile}" "${_optionName}\n")
                endif()
            else()
                # non-flag option with value
                file(APPEND "${outfile}" "${_optionName}=${_variableValue}\n")
            endif()
        endif()
    endforeach()
endfunction()
