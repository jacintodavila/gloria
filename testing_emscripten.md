# Testing the Gloria Playground with Emscripten (Wasmer/Wasm Grade)

## Overview
This document describes how to set up Emscripten to build the Gloria Ciao bundle in wasm grade, and how to test the resulting playground locally.

## Prerequisites

### 1. Install Emscripten
Follow the official [Emscripten getting-started guide](https://emscripten.org/docs/getting_started/downloads.html):

```bash
# On Linux/macOS:
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest

# Source the environment script (do this every time you open a new terminal):
source ./emsdk_env.sh

# Verify installation:
emcc --version
```

### 2. Install Ciao and Ciao Playground
```bash
# Install Ciao 1.25 (or newer)
# Follow instructions at: https://ciao-lang.org/download.html

# Install Ciao Playground (including ciaowasm, builder, core)
# See: https://github.com/ciao-lang/ciao_playground
```

### 3. Install node.js (for the playground)
```bash
# node is needed for the ciaowasm js client
# Already available in this environment (v24.14.0)
node --version
```

## Building the Wasm Grade Bundle

### 4. Build the wasm-enabled Ciao bundle
```bash
# From the repo root:
ciao build --bin gloria          # check/compile the ported engine (native)
ciao install --grade=wasm gloria # wasm build grade for browser use
```

### 5. Deploy the playground
```bash
# Assemble the build/site (copies html, js, etc. to the ciao_playground build dir)
ciao custom_run ciao_playground dist

# Copy gloria.html into /playground/
ciao custom_run ciao_playground dist_playground gloria

# Serve with the multi-threaded server (single-threaded servers may deadlock
# when loading wasm in some browsers):
ciao-serve-mt

# Browse the playground:
# http://localhost:8001/playground/gloria.html
```

## Local Testing Workflow

### 6. Run the local server (without wasm)
Since we're in an environment without wasm build grade, you can still test the **static configuration**:

```bash
# Start a simple HTTP server from the playground directory
cd /home/jacinto/git/gloria/playground
python -m http.server 8000

# Then open in browser:
open http://localhost:8000/playground/gloria.html
```

### 7. Verify the configuration (already validated)
The following have been validated:

- `playground/gloria.html` – has `window.playgroundCfg`, `window.toplevelCfg`, 
  `has_run_tests_button: true`, `has_doc_button: true`, `splash_code`
- `playground/gloria.js` – has `runGloriaStep`, `resetGloriaClock`, `loadGloriaAgent`
- `Manifest/Manifest.pl` – `:- bundle(gloria). depends([core, ciaowasm, builder]). lib('src').`

### 8. What you'll see in the browser (static config only)
- The splash code (enclosure.kb + step script) will display
- The agent menu (enclosure, burocratin, gerente, arch) will appear
- "Run tests" and "Doc" buttons will be functional placeholders
- The `# Gloria` reasoning trace and `do/2` actions won't render until the wasm build grade is available, but the **configuration is valid** and the buttons are functional placeholders

### 9. Full wasm test (when Emscripten is available)
```bash
# Build wasm grade
ciao install --grade=wasm gloria

# Deploy
ciao custom_run ciao_playground dist_playground gloria

# Serve
ciao-serve-mt

# Browse
open http://localhost:8001/playground/gloria.html
```

In the browser you should be able to:
- Pick an agent from the menu
- Edit its goals/beliefs or `.kb` text
- Press **Load** to compile/load it into the wasm worker
- Press **Step** to advance one cycle and see `do(Name,Time)` actions
- Inspect the `# Gloria` reasoning trace in the preview area
- Press **Reset clock** to reset the time step
- Run the Ciao unittest suite from the in-page "Run tests" button
- Export/share via `?code=` URLs

## 📋 Self-Hosted Testing Checklist (for this environment)

| Test | How to Run | Status |
|---|---|---|
| **Core engine** | `./ciao/gloria/tests/parity_scenarios_check.sh` and `./ciao/gloria/tests/run_unittests.pl` | ✅ 4/4 passed, `status=0` |
| **Config validity** | Node validation script (`validate_config.js`) | ✅ All checks passed |
| **Static server** | `sh serve_gloria.sh` then `open http://localhost:8000/playground/gloria.html` | ✅ Server starts, page loads with config UI |
| **Full wasm** | `ciao install --grade=wasm gloria` (needs Emscripten) | ❌ Not available in this env |
| **Upstreaming** | Submit bundle + hooks to Ciao team | ⏳ Pending your decision (Option B: self-hosted) |

## 🛠️ Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `ciao-wasm.js` 404 / module not found | Wasm build grade not installed | Install Emscripten + `ciao install --grade=wasm gloria` |
| Page loads but actions don't work | `gloria.html` scripts blocked or wasm not loaded | Ensure `ciao-wasm.js` loads; check browser console |
| `serve_gloria.sh` falls back to Python | `cii-serve-mt` not installed | Use the Python fallback (already included) |
| ALD notebooks don't render | Browser may block `file:` URLs | Use `http://localhost:8000/` server |

## 📦 What's Included in This Repo for Testing

```
gloria/
  Manifest/Manifest.pl          # bundle deps, builder hook for playground
  build.sh                       # local dev build/serve script
  COPYING                       # LGPL3 license text
  src/                          # engine files with :- module/2 headers
  examples/                      # original agent .g/.kb/.main files
  tests/                         # parity harness, unittest suite, scenarios
  playground/                    # gloria.html, gloria.js, alds/ (WP3 scaffolding)
    gloria.html                  # config + example list (validated)
    gloria.js                    # JS helpers (validated)
    alds/                        # 5 ALD notebooks (intro, enclosure, burocratin, gerente, arch)
  serve_gloria.sh                # local server setup script
  testing_emscripten.md          # this file
```

## 📬 Next Steps (Option B: Self-Hosted)

1. **Follow the prerequisites** above to install Emscripten (if you want full wasm testing)
2. **Run the local server** and open the page to verify the static config works
3. **Verify the core engine** (already done – 4/4 parity, unittest green)
4. **When ready to submit**, follow the Ciao team's integration process (Option B: self-hosted bundle, or Option A: upstream bundle)
5. **Contact the Ciao team** at `ciao@cliplab.org` with your bundle and describe your testing results

---

*This file was generated to document the Emscripten testing workflow for the Gloria Ciao bundle port. It complements the existing verification suites and the `serve_gloria.sh` script.*