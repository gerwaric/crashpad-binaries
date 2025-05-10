set(_crashpad_base "${CMAKE_CURRENT_LIST_DIR}/..")

# Figure out platform
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_crashpad_platform "Linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(_crashpad_platform "Linux") #"macOS")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(_crashpad_platform "Windows")
else()
    message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

add_library(crashpad-binaries STATIC IMPORTED)
set_target_properties(crashpad-binaries PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libcrashpad.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)
