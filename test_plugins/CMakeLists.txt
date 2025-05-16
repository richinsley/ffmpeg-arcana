cmake_minimum_required(VERSION 3.14)

project(test_arcana_plugs LANGUAGES CXX C)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# we need this when mixing C++ with arcana ffmpeg libs
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D__STDC_CONSTANT_MACROS")

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

include_directories(
    ${ARCANA_PREFIX}/include
    ${ARCANA_PREFIX}/include/arcana/libavprivate
)

link_directories(
    ${ARCANA_PREFIX}/lib
)

add_library(test_arcana_plugs SHARED
    # test_proto.c 
    test_mux.c 
    # nut.c 
    test_enc.c
    arcana_loader.c
)

target_link_libraries(test_arcana_plugs
    ${FFMPEG_LIBS}
)

install(TARGETS test_arcana_plugs
        LIBRARY DESTINATION ${ARCANA_PREFIX}/lib/testplugs
)
