{
  description = "Nix flake for building the OLLVM obfuscation pass";

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

        llvm = pkgs.llvmPackages_20;

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

        rustLibDir = "${rust}/lib";
        rustSoname =
          let
            files = builtins.attrNames (builtins.readDir rustLibDir);
            matches = builtins.filter (n: builtins.match "^libLLVM\\.so[0-9\\.]*-rust-.*" n != null) files;
          in
          (builtins.head matches);
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
            llvm.llvm
            rust
          ];

          cmakeGenerator = "Ninja";
          cmakeBuildDir = "build";
          cmakeBuildType = "Release";
          cmakeFlags = [
            "-DLLVM_DIR=${llvm.llvm}/lib/cmake/llvm"
            "-DRUST_LIB_DIR=${rustLibDir}"
            "-DRUST_SONAME=${rustSoname}"
          ];

          meta = with pkgs.lib; {
            description = "OLLVM: LLVM Obfuscation Pass";
            maintainers = with maintainers; [ olk ];
          };
        };

        devShells.default = pkgs.mkShell {
          name = "ollvm-dev";
          nativeBuildInputs = with pkgs; [
            cmake
            ninja
          ];
          buildInputs = [
            llvm.llvm
            llvm.clang-tools
            rust
          ];

          shellHook = ''
            if [ ! -d build ]; then
              cmake -G Ninja -S . -B build \
                -DCMAKE_BUILD_TYPE=Debug \
                -DLLVM_DIR=${llvm.llvm}/lib/cmake/llvm \
                -DRUST_LIB_DIR=${rustLibDir} \
                -DRUST_SONAME=${rustSoname}
            fi

            export C_INCLUDE_PATH=${llvm.llvm}/include:$C_INCLUDE_PATH
            export CPLUS_INCLUDE_PATH=${llvm.llvm}/include/c++/v1:${llvm.llvm}/include:$CPLUS_INCLUDE_PATH
          '';
        };

        defaultPackage = self.packages.${system}.ollvm;
      }
    );
}
