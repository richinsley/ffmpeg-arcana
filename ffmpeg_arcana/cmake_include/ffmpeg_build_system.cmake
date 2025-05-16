cmake_minimum_required(VERSION 3.10)

if (${STEP} STREQUAL configure)
    # Encoding string to list
    string(REPLACE "|" ";" CONFIGURE_EXTRAS_ENCODED "${CONFIGURE_EXTRAS}")
    list(REMOVE_ITEM CONFIGURE_EXTRAS_ENCODED "")

    # load the ffmpeg configuration options file
    file(STRINGS ${FFMPEG_OPTIONS_FILE} ffmpeg_conf_options)

    set(CONFIGURE_COMMAND
            ./configure
            --prefix=${PREFIX}
            --incdir=${PREFIX}/include/arcana
            --build-suffix=${ARCANA_SUFFIX}
            --progs-suffix=${ARCANA_SUFFIX}
            --extra-version=${ARCANA_EXTRA_VERSION}
            --enable-shared
            ${ffmpeg_conf_options}
            ${CONFIGURE_EXTRAS_ENCODED}
    )

    execute_process(COMMAND ${CONFIGURE_COMMAND}
                    RESULT_VARIABLE FFMPEG_CONFIG_RESULT
                    ERROR_VARIABLE FFMPEG_ERROR_RESULT)
    if(FFMPEG_CONFIG_RESULT AND NOT FFMPEG_CONFIG_RESULT EQUAL 0)
        message(FATAL_ERROR "${FFMPEG_ERROR_RESULT}")
    endif()
elseif(${STEP} STREQUAL build)
    execute_process(COMMAND make -j${NJOBS}
                    RESULT_VARIABLE FFMPEG_BUILD_RESULT
                    ERROR_VARIABLE FFMPEG_ERROR_RESULT)
    if(FFMPEG_BUILD_RESULT AND NOT FFMPEG_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "${FFMPEG_ERROR_RESULT}")
    endif()
elseif(${STEP} STREQUAL install)
    execute_process(COMMAND make install
                    RESULT_VARIABLE FFMPEG_INSTALL_RESULT
                    ERROR_VARIABLE FFMPEG_ERROR_RESULT)
    if(FFMPEG_INSTALL_RESULT AND NOT FFMPEG_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "${FFMPEG_ERROR_RESULT}")
    endif()
endif()