{
  description = "Nix flake for building the ollvm-pass LLVM plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    llvm-fork = {
      url = "github:rust-lang/llvm-project/rustc/20.1-2025-02-13";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      llvm-fork,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        rustllvm = pkgs.stdenv.mkDerivation {
          pname = "rust-llvm-project";
          version = "20.1-2025-02-13";
          src = llvm-fork;

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
            python3
            git
          ];

          configurePhase = ''
            cmake -G Ninja -S llvm -B build \
              -DCMAKE_INSTALL_PREFIX=$out \
              -DCMAKE_CXX_STANDARD=17 \
              -DCMAKE_BUILD_TYPE=Release \
              -DLLVM_TARGETS_TO_BUILD=X86 \
              -DLLVM_BUILD_LLVM_DYLIB=ON \
              -DLLVM_LINK_LLVM_DYLIB=ON \
              -DLLVM_EXPORT_SYMBOLS_FOR_PLUGINS=ON \
              -DLLVM_ENABLE_BACKTRACES=OFF \
              -DLLVM_INCLUDE_BENCHMARKS=OFF \
              -DLLVM_INCLUDE_EXAMPLES=OFF \
              -DLLVM_INCLUDE_TESTS=OFF \
              -DLLVM_INCLUDE_TOOLS=OFF \
              -DLLVM_INSTALL_UTILS=OFF
          '';

          buildPhase = ''
            ninja -C build
          '';

          installPhase = ''
            ninja -C build install
          '';

          meta.description = "Rust's fork of LLVM";
        };

        ollvm = pkgs.stdenv.mkDerivation {
          pname = "ollvm-pass";
          version = "0.1.0";
          src = ./ollvm-pass;

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
          ];
          buildInputs = [ rustllvm ];

          configurePhase = ''
            cmake -G Ninja -B build \
              -DCMAKE_BUILD_TYPE=Release \
              -DLLVM_DIR=${rustllvm}/lib/cmake/llvm \
              -DLLVM_EXPORT_SYMBOLS_FOR_PLUGINS=ON \
              -DCMAKE_CXX_FLAGS="-Wall -fno-rtti -O3 -march=x86-64-v3 -flto" \
              -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath,${rustllvm}/lib" \
              -DCMAKE_INSTALL_RPATH="${rustllvm}/lib"
          '';

          buildPhase = ''
            ninja -C build
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp build/obfuscation/libollvm.so $out/lib/
          '';
        };
      in
      {
        packages.ollvm-pass = ollvm;
        defaultPackage = self.packages.${system}.ollvm-pass;
      }
    );
}
