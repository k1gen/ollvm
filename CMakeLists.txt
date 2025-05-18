cmake_minimum_required(VERSION 3.20)
project(ollvm-pass LANGUAGES CXX)

find_package(LLVM 20.1 REQUIRED CONFIG)

message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "  LLVMConfig.cmake in ${LLVM_DIR}")

list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
include(AddLLVM)

include_directories(${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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
  src/obfuscation.def

  DEPENDS intrinsics_gen

  LINK_COMPONENTS
    support
    core
    irreader
    linker
)

target_include_directories(ollvm PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)
