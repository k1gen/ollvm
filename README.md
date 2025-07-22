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

**Educational Purposes Only.** This project is provided strictly for self‑education, experimentation, and research. It is **not** intended for use in production environments, commercial products, or any context where security, stability, or compliance is required.

**No Warranty.** The author makes no guarantees regarding the correctness, reliability, performance, or security of this software. You assume all risk associated with its use. The software is provided “as‑is,” without warranty of any kind, express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, or non‑infringement.

**Liability Waiver.** Under no circumstances shall the author, contributors, or their affiliates be liable for any direct, indirect, incidental, special, punitive, or consequential damages whatsoever (including, but not limited to, loss of data, loss of profits, or business interruption), even if advised of the possibility of such damages, arising out of or in connection with the use or inability to use this software.

**Responsible Use.** This tool can modify compiled code and may be misused for obfuscation in malicious software. The author does **not** endorse or condone any illegal, unethical, or harmful activities. It is your responsibility to ensure that any use of this project complies with all applicable laws, regulations, and policies. By using this software, you agree to indemnify and hold harmless the author from any claims, damages, or liabilities arising from your use.

---

*If you are seeking production‑ready obfuscation tools or formal security guarantees, please consult established commercial or open‑source solutions with dedicated security audits.*

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

This project was inspired by the architectural approach of [0xlane's ollvm-rust](https://github.com/0xlane/ollvm-rust), but all code has been independently re‑implemented; the pass itself is KomiMoe's [Arkari](https://github.com/KomiMoe/Arkari)
