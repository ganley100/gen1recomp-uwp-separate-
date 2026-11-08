cmake_minimum_required(VERSION 3.24)

# Which package to build:
#   all  - the multi-game launcher (Gen1RecompUWP)
#   red  - "Gen1Recomp Red", boots Pokemon Red only and reads ROMs from
#          D:\DevelopmentFiles\Gen1Recomp Red
#   ruby - "Gen1Recomp Ruby", boots Pokemon Ruby only and reads ROMs from
#          D:\DevelopmentFiles\Gen1Recomp Ruby
#   firered - "Gen1Recomp FireRed", boots Pokemon FireRed only and reads ROMs
#          from D:\DevelopmentFiles\Gen1Recomp FireRed
# Each package has its own identity, so they all install side by side.
set(GEN1RECOMP_UWP_GAME "all" CACHE STRING "Xbox package to build: all, red, ruby or firered")
set_property(CACHE GEN1RECOMP_UWP_GAME PROPERTY STRINGS all red ruby firered)
if(GEN1RECOMP_UWP_GAME STREQUAL "all")
    set(UWP_PROJECT "Gen1RecompUWP")
    set(UWP_DISPLAY_NAME "Gen1Recomp")
    set(UWP_DESCRIPTION "Gen1Recomp for Xbox Dev Mode")
    set(UWP_PHONE_PRODUCT_ID "5074018d-a46b-4dd3-b7fa-93a1e39858ad")
    set(UWP_BACKGROUND "#101820")
    set(UWP_GAME_ID "")
    set(UWP_DEV_FOLDER "")
    set(UWP_ASSETS_DIR "Assets")
elseif(GEN1RECOMP_UWP_GAME STREQUAL "red")
    set(UWP_PROJECT "Gen1RecompRed")
    set(UWP_DISPLAY_NAME "Gen1Recomp Red")
    set(UWP_DESCRIPTION "Gen1Recomp Red Version for Xbox Dev Mode")
    set(UWP_PHONE_PRODUCT_ID "3f1c6a52-8d0e-4b7a-9c21-5e7d2a4b1f01")
    set(UWP_BACKGROUND "#8B0A0A")
    set(UWP_GAME_ID "red")
    set(UWP_DEV_FOLDER "D:\\DevelopmentFiles\\Gen1Recomp Red")
    set(UWP_ASSETS_DIR "Assets/red")
elseif(GEN1RECOMP_UWP_GAME STREQUAL "ruby")
    set(UWP_PROJECT "Gen1RecompRuby")
    set(UWP_DISPLAY_NAME "Gen1Recomp Ruby")
    set(UWP_DESCRIPTION "Gen1Recomp Ruby Version for Xbox Dev Mode")
    set(UWP_PHONE_PRODUCT_ID "9b4e2d17-6c3a-4f85-a0d9-2c8e1b7f4a02")
    set(UWP_BACKGROUND "#8B0A0A")
    set(UWP_GAME_ID "ruby")
    set(UWP_DEV_FOLDER "D:\\DevelopmentFiles\\Gen1Recomp Ruby")
    set(UWP_ASSETS_DIR "Assets/ruby")
elseif(GEN1RECOMP_UWP_GAME STREQUAL "firered")
    set(UWP_PROJECT "Gen1RecompFireRed")
    set(UWP_DISPLAY_NAME "Gen1Recomp FireRed")
    set(UWP_DESCRIPTION "Gen1Recomp FireRed Version for Xbox Dev Mode")
    set(UWP_PHONE_PRODUCT_ID "c7d93a40-1e5b-4c62-8f3a-6b0e9d2f5a03")
    set(UWP_BACKGROUND "#C2410C")
    set(UWP_GAME_ID "firered")
    set(UWP_DEV_FOLDER "D:\\DevelopmentFiles\\Gen1Recomp FireRed")
    set(UWP_ASSETS_DIR "Assets/firered")
else()
    message(FATAL_ERROR "GEN1RECOMP_UWP_GAME must be all, red, ruby or firered.")
endif()

project(${UWP_PROJECT} LANGUAGES CXX)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
    message(FATAL_ERROR "Configure with a WindowsStore preset.")
endif()

get_filename_component(GAME_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
set(THIRD_PARTY_ROOT "${CMAKE_CURRENT_LIST_DIR}/third_party")
set(LOVE_ROOT "${THIRD_PARTY_ROOT}/love")
set(SDL2_ROOT "${THIRD_PARTY_ROOT}/sdl2")
set(ANGLE_ROOT "${THIRD_PARTY_ROOT}/angle")
set(RUNTIME_ROOT "${THIRD_PARTY_ROOT}/runtime")

set(GEN1RECOMP_VERSION "0.0.0" CACHE STRING "Gen1Recomp release version")
if(NOT GEN1RECOMP_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(FATAL_ERROR "GEN1RECOMP_VERSION must use X.Y.Z format.")
endif()
string(REPLACE "." ";" VERSION_PARTS "${GEN1RECOMP_VERSION}")
foreach(part IN LISTS VERSION_PARTS)
    if(part GREATER 65535)
        message(FATAL_ERROR "MSIX version components cannot exceed 65535.")
    endif()
endforeach()
set(GEN1RECOMP_UWP_PUBLISHER "CN=Gen1Recomp" CACHE STRING
    "Publisher subject from the MSIX signing certificate")
set(UWP_PUBLISHER_XML "${GEN1RECOMP_UWP_PUBLISHER}")
string(REPLACE "&" "&amp;" UWP_PUBLISHER_XML "${UWP_PUBLISHER_XML}")
string(REPLACE "\"" "&quot;" UWP_PUBLISHER_XML "${UWP_PUBLISHER_XML}")
string(REPLACE "<" "&lt;" UWP_PUBLISHER_XML "${UWP_PUBLISHER_XML}")
string(REPLACE ">" "&gt;" UWP_PUBLISHER_XML "${UWP_PUBLISHER_XML}")
set(UWP_PACKAGE_VERSION "${GEN1RECOMP_VERSION}.0")
# Single-game packages read D:\DevelopmentFiles, which needs broad file access.
if(UWP_DEV_FOLDER)
    set(UWP_EXTRA_CAPABILITIES "    <rescap:Capability Name=\"broadFileSystemAccess\" />")
else()
    set(UWP_EXTRA_CAPABILITIES "")
endif()
# Escaped for a C string literal: every backslash doubled.
string(REPLACE "\\" "\\\\" UWP_DEV_FOLDER_C "${UWP_DEV_FOLDER}")
configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/app/game_config.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/game_config.h"
    @ONLY
)
set(PACKAGE_MANIFEST "${CMAKE_CURRENT_BINARY_DIR}/Package.appxmanifest")
configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/Package.appxmanifest.in"
    "${PACKAGE_MANIFEST}"
    @ONLY
)

set(REQUIRED_FILES
    "${THIRD_PARTY_ROOT}/manifest.json"
    "${LOVE_ROOT}/lib/lovestatic.lib"
    "${LOVE_ROOT}/lib/liblove.lib"
    "${LOVE_ROOT}/lib/lua51.lib"
    "${LOVE_ROOT}/bin/love.dll"
    "${LOVE_ROOT}/bin/lua51.dll"
    "${SDL2_ROOT}/include/SDL2/SDL.h"
    "${SDL2_ROOT}/lib/SDL2.lib"
    "${SDL2_ROOT}/bin/SDL2.dll"
    "${ANGLE_ROOT}/bin/libEGL.dll"
    "${ANGLE_ROOT}/bin/libGLESv2.dll"
    "${ANGLE_ROOT}/bin/d3dcompiler_47.dll"
)
foreach(path IN LISTS REQUIRED_FILES)
    if(NOT EXISTS "${path}")
        message(FATAL_ERROR "Missing UWP dependency: ${path}")
    endif()
endforeach()

set(GEN1RECOMP_LOVE "${GAME_ROOT}/.bazinga/work/game.love" CACHE FILEPATH
    "Path to the game.love payload produced by scripts/pack_love.sh")
if(NOT EXISTS "${GEN1RECOMP_LOVE}")
    message(FATAL_ERROR
        "Missing game.love payload: ${GEN1RECOMP_LOVE}\n"
        "Build it with scripts/build_xbox_uwp.sh or scripts/pack_love.sh.")
endif()

set(GAME_ARCHIVE "${CMAKE_CURRENT_BINARY_DIR}/gen1recomp.love")
add_custom_command(
    OUTPUT "${GAME_ARCHIVE}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${GEN1RECOMP_LOVE}" "${GAME_ARCHIVE}"
    DEPENDS "${GEN1RECOMP_LOVE}"
    VERBATIM
)
add_custom_target(gen1recomp_love ALL DEPENDS "${GAME_ARCHIVE}")
set_source_files_properties("${GAME_ARCHIVE}" PROPERTIES GENERATED TRUE)

add_custom_target(verify_uwp_dependencies
    COMMAND powershell -NoProfile -ExecutionPolicy Bypass -File
        "${GAME_ROOT}/scripts/xbox-uwp/verify_dependencies.ps1"
    VERBATIM
)

add_executable(${PROJECT_NAME} WIN32 "app/main.cpp")
add_dependencies(${PROJECT_NAME} gen1recomp_love verify_uwp_dependencies)
set_target_properties(${PROJECT_NAME} PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED YES
    VS_GLOBAL_DefaultLanguage "en-US"
    VS_SDK_REFERENCES "Microsoft.VCLibs, Version=14.0"
)
target_include_directories(${PROJECT_NAME} PRIVATE
    "${SDL2_ROOT}/include/SDL2"
    "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
target_link_libraries(${PROJECT_NAME} PRIVATE
    "${LOVE_ROOT}/lib/lovestatic.lib"
    "${LOVE_ROOT}/lib/liblove.lib"
    "${SDL2_ROOT}/lib/SDL2.lib"
    "${LOVE_ROOT}/lib/lua51.lib"
    WindowsApp.lib
)

set(PACKAGE_ROOT_FILES
    "${PACKAGE_MANIFEST}"
    "${GAME_ARCHIVE}"
    "${LOVE_ROOT}/bin/love.dll"
    "${LOVE_ROOT}/bin/lua51.dll"
    "${SDL2_ROOT}/bin/SDL2.dll"
    "${ANGLE_ROOT}/bin/libEGL.dll"
    "${ANGLE_ROOT}/bin/libGLESv2.dll"
    "${ANGLE_ROOT}/bin/d3dcompiler_47.dll"
)
set_source_files_properties("${PACKAGE_MANIFEST}" PROPERTIES GENERATED TRUE)

set(RUNTIME_NAMES
    brotlicommon.dll brotlidec.dll bz2.dll fmt.dll freetype.dll libpng16.dll
    OpenAL32.dll theora.dll theoradec.dll vorbis.dll vorbisfile.dll ogg.dll z.dll
)
foreach(name IN LISTS RUNTIME_NAMES)
    set(runtime "${RUNTIME_ROOT}/bin/${name}")
    if(NOT EXISTS "${runtime}")
        message(FATAL_ERROR "Missing UWP runtime DLL: ${name}")
    endif()
    list(APPEND PACKAGE_ROOT_FILES "${runtime}")
endforeach()

set_source_files_properties(${PACKAGE_ROOT_FILES} PROPERTIES
    VS_COPY_TO_OUT_DIR Always
    VS_DEPLOYMENT_CONTENT TRUE
    VS_DEPLOYMENT_LOCATION "."
)

file(GLOB PACKAGE_ASSETS CONFIGURE_DEPENDS "${CMAKE_CURRENT_LIST_DIR}/${UWP_ASSETS_DIR}/*.png")
set_source_files_properties(${PACKAGE_ASSETS} PROPERTIES
    VS_DEPLOYMENT_CONTENT TRUE
    VS_DEPLOYMENT_LOCATION "Assets"
)

file(GLOB PACKAGE_LICENSES CONFIGURE_DEPENDS "${THIRD_PARTY_ROOT}/licenses/*.txt")
set_source_files_properties(${PACKAGE_LICENSES} PROPERTIES
    VS_TOOL_OVERRIDE "Content"
    VS_COPY_TO_OUT_DIR Always
    VS_DEPLOYMENT_CONTENT TRUE
    VS_DEPLOYMENT_LOCATION "licenses"
)
target_sources(${PROJECT_NAME} PRIVATE
    ${PACKAGE_ROOT_FILES}
    ${PACKAGE_ASSETS}
    ${PACKAGE_LICENSES}
)
