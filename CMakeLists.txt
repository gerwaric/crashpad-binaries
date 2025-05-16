cmake_minimum_required(VERSION 3.15)

project(crashpad NONE)  # No real build, just define targets

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

#set(crashpad_root "${CMAKE_CURRENT_LIST_DIR}")

# Determine the platform
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(platform "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(platform "macos")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(platform "windows")
else()
    message(FATAL_ERROR "Crashpad: unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

# Setup paths
set(platform_bin "${CMAKE_CURRENT_LIST_DIR}/bin/${platform}")
set(platform_lib "${CMAKE_CURRENT_LIST_DIR}/lib/${platform}")
set(crashpad_include "${CMAKE_CURRENT_LIST_DIR}/include")

# Set the name of the crashpad_handler program
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(crashpad_handler "crashpad_handler.exe")
else()
    set(crashpad_handler "crashpad_handler")
endif()

# Add the crashpad_handler as a global target
add_executable(crashpad::handler IMPORTED GLOBAL)
set_target_properties(crashpad::handler PROPERTIES
    IMPORTED_LOCATION "${platform_bin}/${crashpad_handler}"
)

# Add the crashpad library as an interface target
add_library(crashpad INTERFACE)
target_link_libraries(crashpad INTERFACE
    crashpad::client
    crashpad::common
    crashpad::util
    crashpad::base
)

# Add Advapi32 for Windows
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_link_libraries(crashpad INTERFACE Advapi32)
endif()

# Add each of the crashpad::* library targets
foreach(name IN ITEMS client common util base)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(lib_release "MD/${name}.lib")
        set(lib_debug "MDd/${name}.lib")
    else()
        set(lib_release "lib${name}.a")
        set(lib_debug "lib${name}.a")
    endif()

    add_library(crashpad::${name} IMPORTED STATIC GLOBAL)
    set_target_properties(crashpad::${name}
        PROPERTIES
        IMPORTED_LOCATION_RELEASE "${platform_lib}/release/${lib_release}"
        IMPORTED_LOCATION_DEBUG "${platform_lib}/debug/${lib_debug}"
        INTERFACE_INCLUDE_DIRECTORIES "${crashpad_include}/crashpad;${crashpad_include}/mini_chromium"
    )

endforeach()

#[[

add_library(crashpad::common STATIC IMPORTED GLOBAL)
set_target_properties(crashpad::common PROPERTIES
    IMPORTED_LOCATION "${_crashpad_common}"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/include/crashpad;${CMAKE_CURRENT_LIST_DIR}/include/mini_chromium"
)

add_library(crashpad::util STATIC IMPORTED GLOBAL)
set_target_properties(crashpad::util PROPERTIES
    IMPORTED_LOCATION "${_crashpad_util}"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/include/crashpad;${CMAKE_CURRENT_LIST_DIR}/include/mini_chromium"
)

add_library(crashpad::base STATIC IMPORTED GLOBAL)
set_target_properties(crashpad::base PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/include/crashpad;${CMAKE_CURRENT_LIST_DIR}/include/mini_chromium"
)

#]]
