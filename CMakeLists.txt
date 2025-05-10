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

add_library(crashpad::binaries INTERFACE)
target_link_libraries(crashpad::binaries INTERFACE
    crashpad::client
    crashpad::common
    crashpad::util
    mini_chromium::base
)

add_library(crashpad::client STATIC IMPORTED)
set_target_properties(crashpad::client PROPERTIES
    IMPORTED_LOCATION "${CMAKE_SOURCE_DIR}/lib/${_crashpad_platform}/libclient.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/include"
)

add_library(crashpad::common STATIC IMPORTED)
set_target_properties(crashpad::common PROPERTIES
    IMPORTED_LOCATION "${CMAKE_SOURCE_DIR}/lib/${_crashpad_platform}/libcommon.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/include"
)

add_library(crashpad::util STATIC IMPORTED)
set_target_properties(crashpad::util PROPERTIES
    IMPORTED_LOCATION "${CMAKE_SOURCE_DIR}/lib/${_crashpad_platform}/libutil.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/include"
)

add_library(mini_chromium::base STATIC IMPORTED)
set_target_properties(mini_chromium::base PROPERTIES
    IMPORTED_LOCATION "${CMAKE_SOURCE_DIR}/lib/${_crashpad_platform}/libbase.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/include"
)

