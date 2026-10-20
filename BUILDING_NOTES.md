# Building the Gloria Ciao Bundle

## Builder Target Error Fix

The error `'gloria' does not look like a valid builder target` occurs because the Ciao build system needs the bundle to be reachable from `CIAOROOT` or `CIAOPATH`, and/or properly activated in a catalog.

### Quick Fix: Set Environment Variables

```bash
# Set the Ciao environment
export CIAOROOT="$HOME/.ciaoroot/v1.25.0-m1-20260919145856"
export CIAOPATH="$PWD/gloria"  # or wherever your bundle lives

# Then try building again
ciao build --bin gloria
```

### Alternative: Add to Ciao Catalog

If the above doesn't work, you may need to add the bundle to Ciao's catalog. Create or edit `$HOME/.ciao/catalog` (or the catalog file indicated by your Ciao installation):

```prolog
:- catalog(gloria).
  location('/home/jacinto/git/gloria').
  activate.
```

Then source the Ciao environment and retry:

```bash
source $CIAO_ENV  # or similar
ciao build --bin gloria
```

### Native Build (Already Verified)

The core engine has been verified without using the builder:

```bash
# These tests pass regardless of the builder target issue:
export PATH="$HOME/.ciaoroot/v1.25.0-m1/build/bin:$PATH"
./ciao/gloria/tests/parity_scenarios_check.sh    # 6/6 PARITY OK
./ciao/gloria/tests/run_unittests.pl             # status=0, 4/4 passed
```

### Wasmer/Wasm Grade Build (When Emscripten Available)

```bash
# 1. Install Emscripten (see testing_emscripten.md)
# 2. Build the wasm grade:
ciao install --grade=wasm gloria

# 3. Deploy the playground:
ciao custom_run ciao_playground dist_playground gloria

# 4. Serve and test:
ciao-serve-mt  # or python -m http.server from playground/
open http://localhost:8001/playground/gloria.html
```

### Directory Structure for Builder Recognition

Ensure your bundle layout matches expectations:

```
gloria/
  Manifest/Manifest.pl          # bundle declaration (already correct)
  build.sh                       # build script (already created)
  COPYING                       # LGPL3 license
  src/                          # engine files
  examples/                     # agent .g/.kb/.main files
  tests/                        # parity harness, unittest suite
  playground/                   # gloria.html (generated), mkpage.py, agents/, alds/
  BUILDING_NOTES.md              # this file
```

## Recommended Workflow

1. **Set CIAOROOT** and try `ciao build --bin gloria`
2. **If that fails**, use the native test suite (already verified)
3. **For wasm testing**, follow `testing_emscripten.md`
4. **Run the local server** with `sh serve_gloria.sh` to verify the HTML config

## Summary

- **Native Ciao engine**: ✅ Verified (6/6 agents parity OK, unittest green)
- **Builder target**: ⚠️ Needs environment config (CIAOROOT/CIAOPATH) or catalog registration
- **Wasm/Emscripten**: 📖 Instructions documented in `testing_emscripten.md`
- **Local static testing**: ✅ Ready with `serve_gloria.sh`