# ollvm for Linux, made for use with latest nightly Rust toolchains

Currently, all obfuscation techniques work except for Control-flow flattening, which makes rustc crash horribly.

The techniques listed below work, as well as any combination of them (`irobf(irobf-indbr,irobf-icall,irobf-indgv,irobf-cse,irobf-cie,irobf-cfe)` gives you a ~313% size increase):

- Indirect Call Obfuscation (`irobf-icall`, makes the final executable ~40% larger)
- Indirect Branch Obfuscation (`irobf-indbr`, final executable roughly twice as large)
- Indirect Global Variable Obfuscation (`irobf-indgv`, ~4% size increase)
- Constant String Encryption (`irobf-cse`, doesn't really encrypt anything for now, but the target compiles successfully)
- Constant Integer Encryption (`irobf-cie`, ~55% size increase, usefulness questionable)
- Constant FP Encryption (`irobf-cfe`, no size difference)

The project is in WIP state, and because my LLVM and C++ skills are not the best, I can't guarantee that it will ever be fully functional.
Next to come is cross-platform support, Control-flow flattening after that, then maybe a fix for the String Encryption. No promises, though.

## Disclaimer

<...>

## Building

```
nix build
```

Really. I put a lot of effort into making this as painless as possible.

## Usage

1. Put result/lib/ollvm.so somewhere close to the project you want to use it with, e.g. in the root of your project.
2. Add this to your Cargo.toml (nightly toolchains only):

```
cargo-features = ["profile-rustflags"]
rustflags = [
    "-Zllvm-plugins=<path-to-ollvm.so>",
    "-Cpasses=irobf(irobf-indbr,irobf-icall,irobf-indgv,irobf-cff,irobf-cse,irobf-cie,irobf-cfe)",
]
```

## References and Credits

[https://github.com/0xlane/ollvm-rust]

[https://github.com/KomiMoe/Arkari]
