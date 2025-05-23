# ollvm

## Build

1. Clone https://github.com/rust-lang/llvm-project/tree/rustc/20.1-2025-02-13 and cd into it: `git clone git@github.com:rust-lang/llvm-project.git -b rustc/20.1-2025-02-13 --depth 1 && cd llvm-project`
2. Create build directory beside llvm folder: `mkdir build && cd build`
3. Generate ninja build files with the following command: `cmake -G Ninja ../llvm -DCMAKE_INSTALL_PREFIX=/workspace/ollvm/llvm_x64 -DCMAKE_CXX_STANDARD=17 -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_EXPORT_SYMBOLS_FOR_PLUGINS=ON -DLLVM_ENABLE_BACKTRACES=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_TOOLS=OFF -DLLVM_INSTALL_UTILS=OFF`
4. Build and install llvm: `ninja -j"$(nproc)" install`
5. Cd into the ollvm-pass directory and create the build directory there: `cd ../../ollvm-pass && mkdir build && cd build`
6. Build the ollvm pass plugin: `cmake -G Ninja .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DLLVM_DIR=<...>/llvm_x64/lib/cmake/llvm -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=x86-64-v3 -flto" -DCMAKE_SHARED_LINKER_FLAGS="-s" && ninja`

or just run `nix build`

## Usage

1. Put libollvm.so inside your cargo (where Cargo.toml is located).
2. Add this to your Cargo.toml (nightly only):

```
cargo-features = ["profile-rustflags"]
rustflags = [
    "-Zllvm-plugins=libollvm.so",
    "-Cpasses=irobf(irobf-indbr,irobf-icall,irobf-indgv,irobf-cff,irobf-cse,irobf-cie,irobf-cfe)",
]
```

## References

[https://github.com/0xlane/ollvm-rust]
[https://github.com/KomiMoe/Arkari]
