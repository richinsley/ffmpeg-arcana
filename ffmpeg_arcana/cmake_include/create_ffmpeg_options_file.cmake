function(create_ffmpeg_options_file dir outfile)
  # iterate over the cmake cache of variables and look for ones that start with "FFOPT_"
  get_property(_variableNames DIRECTORY ${dir} PROPERTY VARIABLES)
  list (SORT _variableNames)
  file(WRITE "${outfile}" "")
  foreach (_variableName ${_variableNames})
    get_directory_property(_variableValue DIRECTORY ${dir} DEFINITION ${_variableName})
    # if the variable starts with "FFOPT_", we need to convert tp ffmpeg's ./configure options
    string(FIND "${_variableName}" "FFOPT_" out)
    if("${out}" EQUAL 0)
        # remove the FFOPT_ prefix
        string(REPLACE "FFOPT_" "" _variableName "${_variableName}")

        # replace '_' with '-' and make all lower case and prepend '--'
        string(REPLACE "_" "-" _variableName "${_variableName}")
        string(TOLOWER ${_variableName} _variableName)
        string(PREPEND _variableName "--")

        # is it a flag? if so, skip it if it is 'false'
        string(TOLOWER ${_variableValue} _vtolower)
        if(_vtolower STREQUAL "true" OR _vtolower STREQUAL "false")
            if(_vtolower STREQUAL "true")
                file(APPEND "${outfile}" "${_variableName}\n")
            endif()
        else()
            # non-flag option
            file(APPEND "${outfile}" "${_variableName}=${_variableValue}\n")
        endif()
     endif()
  endforeach()
endfunction(create_ffmpeg_options_file)