cmake_minimum_required(VERSION 3.20)
project(ollvm LANGUAGES CXX)

set(BUILD_SHARED_LIBS ON)
set(LLVM_EXPORT_SYMBOLS_FOR_PLUGINS ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

add_compile_options(
  $<$<CONFIG:Release>:-march=x86-64-v3>
  $<$<CONFIG:Release>:-flto>
  -Wall
  -fPIC
  -ffunction-sections
  -fdata-sections
  -fno-rtti
  -fno-exceptions
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(LLVM 20.1 REQUIRED CONFIG)
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

set(RUST_LIB_DIR "" CACHE PATH   "Directory containing Rust's libLLVM.so")
set(RUST_SONAME "" CACHE STRING "Exact Rust libLLVM filename")

if(RUST_LIB_DIR AND RUST_SONAME)
  set(_RUST_LLVM "${RUST_LIB_DIR}/${RUST_SONAME}")
  message(STATUS "Using Rust LLVM dylib: ${_RUST_LLVM}")

  set(_LLVM_IMPORTED_TARGETS
      LLVM::LLVM LLVM::Support LLVM::Core LLVM::IRReader LLVM::Linker LLVM)

  foreach(tgt IN LISTS _LLVM_IMPORTED_TARGETS)
    if(TARGET ${tgt})
      set_target_properties(${tgt} PROPERTIES IMPORTED_LOCATION "${_RUST_LLVM}")
      foreach(cfg RELEASE RELWITHDEBINFO MINSIZEREL DEBUG)
        set_target_properties(${tgt} PROPERTIES
          IMPORTED_LOCATION_${cfg} "${_RUST_LLVM}")
      endforeach()
    endif()
  endforeach()

  set(CMAKE_BUILD_RPATH   "${RUST_LIB_DIR};${CMAKE_BUILD_RPATH}")
  set(CMAKE_INSTALL_RPATH "${RUST_LIB_DIR};${CMAKE_INSTALL_RPATH}")
endif()

set(LLVM_LINK_LLVM_DYLIB ON)
set(LLVM_USE_STATIC_LIBS OFF)

add_llvm_library(ollvm MODULE
  src/ConstantFPEncryption.cpp
  src/ConstantIntEncryption.cpp
  src/CryptoUtils.cpp
  src/Utils.cpp
  src/ObfuscationPassManager.cpp
  src/ObfuscationOptions.cpp
  src/IndirectBranch.cpp
  src/IndirectCall.cpp
  src/IndirectGlobalVariable.cpp
  src/Flattening.cpp
  src/StringEncryption.cpp
  src/LegacyLowerSwitch.cpp

  DEPENDS intrinsics_gen

  LINK_COMPONENTS
    support
    core
    irreader
    linker
)

target_include_directories(ollvm PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${LLVM_INCLUDE_DIRS}
)
target_compile_definitions(ollvm PRIVATE ${LLVM_DEFINITIONS})
target_link_options(ollvm PRIVATE -static-libstdc++ -static-libgcc)
