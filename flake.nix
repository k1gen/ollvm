{
  description = "Nix flake for building the ollvm LLVM obfuscation pass";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        llvm = pkgs.llvmPackages_20.llvm;
        rust = pkgs.rust-bin.selectLatestNightlyWith (
          tc:
          tc.default.override {
            extensions = [
              "rust-src"
              "llvm-tools-preview"
            ];
            targets = [ "x86_64-unknown-linux-gnu" ];
          }
        );
      in
      {
        packages.ollvm = pkgs.stdenv.mkDerivation {
          pname = "ollvm";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            ninja
          ];
          buildInputs = [
            llvm
            rust
          ];

          configurePhase = ''
            cmake -G Ninja -B build \
              -DCMAKE_BUILD_TYPE=Release \
              -DLLVM_DIR=${llvm}/lib/cmake/llvm \
              -DLLVM_EXPORT_SYMBOLS_FOR_PLUGINS=ON \
              -DBUILD_SHARED_LIBS=ON \
              -DLLVM_LINK_LLVM_DYLIB=ON \
              -DCMAKE_CXX_FLAGS="-Wall -fno-rtti -O3 -march=x86-64-v3 -flto" \
              -DCMAKE_SHARED_LINKER_FLAGS="-L${rust}/lib -Wl,-rpath,${rust}/lib -l:libLLVM.so.20.1-rust-1.89.0-nightly"
          '';

          buildPhase = ''
            ninja -C build
          '';

          installPhase = ''
            mkdir -p $out/lib
            cp build/ollvm.so $out/lib/
          '';

          meta = with pkgs.lib; {
            description = "OLLVM: LLVM Obfuscation Pass";
            maintainers = with maintainers; [ olk ];
          };
        };
        defaultPackage = self.packages.${system}.ollvm;
      }
    );
}
