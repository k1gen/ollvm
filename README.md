# ollvm

## Prerequisites
- CMake 3.31.1
- Visual Studio 2022 (Desktop Development with C++)
  - MSVC v143 - VS 2022 C++ x64/x86 build tools   
  - Windows 11 SDK (10.0.26100.0)
  - C++ CMake tools for Windows
- Rust Nightly 1.85.0

## Build
1. Clone https://github.com/rust-lang/llvm-project/tree/rustc/19.1-2024-09-17
2. Create build directory beside llvm folder.
```
mkdir build
cd build
```
3. Generate visual studio solutions
```
cmake -G "Visual Studio 17 2022" ../llvm -DCMAKE_INSTALL_PREFIX="./llvm_x64" -DCMAKE_CXX_STANDARD=17 -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_EXPORT_SYMBOLS_FOR_PLUGINS=ON -DLLVM_ENABLE_BACKTRACES=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_TOOLS=OFF -DLLVM_INSTALL_UTILS=OFF 
```
4. Build and install (move the content of llvm_x64 folder to C:/Program Files/LLVM)
```
cmake --build . -j4 --config Release
cmake --install .
```

## Usage
1. Put ollvm.dll inside your cargo (where Cargo.toml located).
2. Add this to your Cargo.toml. (Due to this you'll need nightly toolchain.)
```
cargo-features = ["profile-rustflags"]
rustflags = [
    "-Zllvm-plugins=ollvm.dll",
    "-Cpasses=irobf(irobf-indbr,irobf-icall,irobf-indgv,irobf-cff,irobf-cse,irobf-cie,irobf-cfe)",
]
```

## References
[https://github.com/0xlane/ollvm-rust]
[https://github.com/KomiMoe/Arkari]