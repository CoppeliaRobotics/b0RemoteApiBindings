cmake_minimum_required(VERSION 3.15)
project(bubbleRobClient_b0RemoteApi)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_MACOSX_RPATH 1)

find_package(Boost REQUIRED COMPONENTS thread system filesystem)

if(NOT LIBPLUGIN_DIR)
    if(DEFINED ENV{COPPELIASIM_ROOT_DIR})
        set(LIBPLUGIN_DIR $ENV{COPPELIASIM_ROOT_DIR}/programming/libPlugin)
    else()
        set(LIBPLUGIN_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../libPlugin)
    endif()
endif()
list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules
    ${LIBPLUGIN_DIR}/cmake)
find_package(CoppeliaSim 4.1.0.0 REQUIRED)
find_package(BlueZero REQUIRED)

coppeliasim_add_executable(bubbleRobClient_b0RemoteApi SOURCES bubbleRobClient.cpp ../b0RemoteApi)
target_include_directories(bubbleRobClient_b0RemoteApi PRIVATE ${BLUEZERO_INCLUDE_DIRS})
target_include_directories(bubbleRobClient_b0RemoteApi PRIVATE ..)
target_include_directories(bubbleRobClient_b0RemoteApi PRIVATE ../msgpack-c/include)
target_link_libraries(bubbleRobClient_b0RemoteApi Boost::system)
target_link_libraries(bubbleRobClient_b0RemoteApi ${BLUEZERO_LIBRARIES})
