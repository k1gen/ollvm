cmake_minimum_required(VERSION 3.20)
project(ollvm-pass LANGUAGES CXX)

set(BUILD_SHARED_LIBS ON)
set(LLVM_EXPORT_SYMBOLS_FOR_PLUGINS ON)
set(LLVM_LINK_LLVM_DYLIB ON)

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

set(CMAKE_CXX_STANDARD          17)
set(CMAKE_CXX_EXTENSIONS        OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(LLVM 20.1 REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION} in ${LLVM_DIR}")

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

# -DRUST_LIB_DIR=/nix/store/…/rust/lib
# -DRUST_SONAME=libLLVM.so.20.1-rust-1.89.0-nightly
set(RUST_LIB_DIR   "" CACHE PATH   "Directory that contains Rust's libLLVM")
set(RUST_SONAME    "" CACHE STRING "Exact Rust libLLVM filename")

if(RUST_LIB_DIR AND RUST_SONAME)
  set(CMAKE_BUILD_RPATH   "${RUST_LIB_DIR}")
  set(CMAKE_INSTALL_RPATH "${RUST_LIB_DIR}")

  add_link_options("-L${RUST_LIB_DIR}"
                   "-Wl,-rpath,${RUST_LIB_DIR}"
                   "-l:${RUST_SONAME}")
endif()

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
