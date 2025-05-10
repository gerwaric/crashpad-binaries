set(_crashpad_base "${CMAKE_CURRENT_LIST_DIR}/..")

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

add_library(Crashpad INTERFACE)
target_link_libraries(Crashpad INTERFACE
    Crashpad::Client
    Crashpad::Common
    Crashpad::Util
    MiniChromium::Base
)

add_library(Crashpad::Client STATIC IMPORTED)
set_target_properties(Crashpad::Client PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libclient.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)

add_library(Crashpad::Common STATIC IMPORTED)
set_target_properties(Crashpad::Common PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libcommon.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)

add_library(Crashpad::Util STATIC IMPORTED)
set_target_properties(Crashpad::Util PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libutil.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)

add_library(MiniChromium::Base STATIC IMPORTED)
set_target_properties(MiniChromium::Base PROPERTIES
    IMPORTED_LOCATION "${_crashpad_base}/lib/${_crashpad_platform}/libbase.a"
    INTERFACE_INCLUDE_DIRECTORIES "${_crashpad_base}/include"
)
