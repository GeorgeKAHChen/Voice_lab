cmake_minimum_required(VERSION 3.10)

project(amakawa_core_library VERSION 0.0.1 LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(amakawa_core SHARED
  "miniaudio_impl.c"
  "dsp.cpp"
  "amakawa_core.cpp"
)

set_target_properties(amakawa_core PROPERTIES
  PUBLIC_HEADER amakawa_core.h
  OUTPUT_NAME "amakawa_core"
  C_VISIBILITY_PRESET default
)

target_compile_definitions(amakawa_core PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(amakawa_core PRIVATE "-Wl,-z,max-page-size=16384")
  target_link_libraries(amakawa_core PRIVATE log android)
elseif (UNIX AND NOT APPLE)
  target_link_libraries(amakawa_core PRIVATE pthread dl m)
endif()
