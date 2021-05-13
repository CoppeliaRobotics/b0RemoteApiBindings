cmake_minimum_required(VERSION 2.8.12)
include(CMakeParseArguments)

if(DEFINED ENV{BLUEZERO_DIR})
    set(BLUEZERO_DIR_DEFAULT $ENV{BLUEZERO_DIR})
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../bluezero")
    set(BLUEZERO_DIR_DEFAULT "${CMAKE_CURRENT_SOURCE_DIR}/../bluezero")
endif()
file(TO_CMAKE_PATH "${BLUEZERO_DIR_DEFAULT}" BLUEZERO_DIR_DEFAULT)
set(BLUEZERO_DIR "${BLUEZERO_DIR_DEFAULT}" CACHE STRING "BlueZero directory")

if(NOT EXISTS "${BLUEZERO_DIR}")
    message(FATAL_ERROR "BLUEZERO_DIR (${BLUEZERO_DIR}) does not contain a valid directory")
endif()

if(EXISTS "${BLUEZERO_DIR}/build/CMakeFiles")
    set(BLUEZERO_BUILD_DIR_DEFAULT "${BLUEZERO_DIR}/build")
elseif(EXISTS "${BLUEZERO_DIR}/build/x86-Debug/CMakeFiles")
    set(BLUEZERO_BUILD_DIR_DEFAULT "${BLUEZERO_DIR}/build/x86-Debug")
elseif(EXISTS "${BLUEZERO_DIR}/build/x86-Release/CMakeFiles")
    set(BLUEZERO_BUILD_DIR_DEFAULT "${BLUEZERO_DIR}/build/x86-Release")
endif()
set(BLUEZERO_BUILD_DIR "${BLUEZERO_BUILD_DIR_DEFAULT}" CACHE STRING "BlueZero build directory")

if(NOT EXISTS "${BLUEZERO_BUILD_DIR}")
    message(FATAL_ERROR "BLUEZERO_BUILD_DIR (${BLUEZERO_BUILD_DIR}) does not contain a valid directory")
endif()

set(BLUEZERO_INCLUDE_SEARCH_PATHS
    /usr/include
    /usr/local/include
    ${BLUEZERO_DIR}/include
    ${BLUEZERO_BUILD_DIR}/include
)
find_path(BLUEZERO_INCLUDE_DIR_1 b0/b0.h HINTS ${BLUEZERO_INCLUDE_SEARCH_PATHS})
find_path(BLUEZERO_INCLUDE_DIR_2 b0/config.h HINTS ${BLUEZERO_INCLUDE_SEARCH_PATHS})

if(WIN32)
    set(BLUEZERO_LIBRARY_NAME b0-static)
else()
    set(BLUEZERO_LIBRARY_NAME b0)
endif()

set(BLUEZERO_LIBRARY_SEARCH_PATHS
    ${BLUEZERO_BUILD_DIR}/Release
    ${BLUEZERO_BUILD_DIR}/Debug
    ${BLUEZERO_BUILD_DIR}
)
find_library(BLUEZERO_LIBRARY NAMES ${BLUEZERO_LIBRARY_NAME} HINTS ${BLUEZERO_LIBRARY_SEARCH_PATHS})

if(WIN32)
    find_package(Boost 1.54 REQUIRED COMPONENTS thread system regex timer filesystem serialization program_options)
    if(VCPKG_TOOLCHAIN)
        find_package(ZeroMQ CONFIG REQUIRED)
        set(ZMQ_LIBRARY libzmq)
    else()
        find_package(ZMQ 4.1.4 REQUIRED)
    endif()
    find_package(ZLIB)
    find_package(LZ4)
endif()

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set BLUEZERO_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(BlueZero  DEFAULT_MSG
    BLUEZERO_LIBRARY BLUEZERO_INCLUDE_DIR_1 BLUEZERO_INCLUDE_DIR_2)

if(WIN32)
    set(BLUEZERO_LIBRARIES
        ${Boost_LIBRARIES}
        ${ZMQ_LIBRARY}
        ${BLUEZERO_LIBRARY}
    )
    if(ZLIB_FOUND)
        set(BLUEZERO_LIBRARIES ${BLUEZERO_LIBRARIES} ${ZLIB_LIBRARIES})
    endif()
    if(LZ4_FOUND)
        set(BLUEZERO_LIBRARIES ${BLUEZERO_LIBRARIES} ${LZ4_LIBRARY})
    endif()
else()
    set(BLUEZERO_LIBRARIES ${Boost_LIBRARIES} ${BLUEZERO_LIBRARY})
endif()

unset(BLUEZERO_LIBRARY CACHE)
unset(ZMQ_LIBRARY CACHE)
set(BLUEZERO_INCLUDE_DIRS
    ${Boost_INCLUDE_DIRS}
    ${BLUEZERO_INCLUDE_DIR_1}
    ${BLUEZERO_INCLUDE_DIR_2}
)
unset(BLUEZERO_INCLUDE_DIR_1 CACHE)
unset(BLUEZERO_INCLUDE_DIR_2 CACHE)

mark_as_advanced(BLUEZERO_LIBRARIES BLUEZERO_INCLUDE_DIRS)
