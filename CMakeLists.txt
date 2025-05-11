cmake_minimum_required(VERSION 3.15)

project(crashpad NONE)  # No real build, just define targets

# Figure out platform
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_crashpad_platform "Linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(_crashpad_platform "macOS")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(_crashpad_platform "Windows")
else()
    message(FATAL_ERROR "Crashpad: unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

if(NOT DEFINED crashpad_SOURCE_DIR)
    set(_crashpad_base "${CMAKE_SOURCE_DIR}")
else()
    set(_crashpad_base "${crashpad_SOURCE_DIR}")
endif()

add_library(crashpad::binaries INTERFACE)
target_link_libraries(crashpad::binaries INTERFACE
    crashpad::binaries::client
    crashpad::binaries::common
    crashpad::binaries::util
    crashpadbinaries::mini_chromium::base
)

add_library(crashpad::binaries::client STATIC IMPORTED)
set_target_properties(crashpad::binaries::client PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libclient.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)
target_link_libraries(crashpad::binaries::client INTERFACE
    crashpad::binaries::mini_chromium::base
)

add_library(crashpad::binaries::common STATIC IMPORTED)
set_target_properties(crashpad::binaries::common PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libcommon.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)

add_library(crashpad::binaries::util STATIC IMPORTED)
set_target_properties(crashpad::binaries::util PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libutil.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)

add_library(crashpad::binaries::mini_chromium::base STATIC IMPORTED)
set_target_properties(crashpad::binaries::mini_chromium::base PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libbase.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)

