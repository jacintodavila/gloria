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

### 6. Regenerate and run the page

The page is generated: `playground/gloria.html` and the self-contained agent
sources in `playground/agents/*.pl` come from `src/agents/`.  After changing
an agent (or adding one), regenerate both:

```bash
python3 playground/mkpage.py     # from the repo root
```

Then serve the assembled site (`$CIAOROOT/build/site`) and open the page:

```bash
./serve_gloria.sh                # http://localhost:8000/playground/gloria.html
```

Use the multi-threaded server: single-threaded servers may deadlock when the
worker loads the wasm engine.

### 7. What the page does

- The editor holds a **self-contained** Gloria agent: a `:- module(<agent>, [])`
  directive, the `abd/1` / `observable/1` configuration and the `if_/2` / `def/2`
  knowledge base, all in one `.pl` file.  The *Examples* menu replaces it with
  any of the six shipped agents.
- The website explains the flow: `Load ▶` uploads the editor to the wasm worker
  and runs `gloria:load_agent_code('/<agent>.pl')`, which builds the reified
  agent from that file (the agent id is the file's basename).
- Reasoning steps are ordinary queries typed in the top level:

  ```prolog
  ?- prolog_agent(enclosure, 0, 400, [time_day(am), it_is(sunny)], Actions).
  ?- gloria_step(enclosure, 0, 400, [time_day(am), it_is(sunny)], Ng, Og, Actions).
  ```

  They are written *unqualified*; the page rewrites them into the `gloria`
  module in Prolog (`disguise_trans_query/3`, see
  `library(gloria/gloria_playground)`), because the top level runs in `user`
  and the engine is a single module -- qualifying them by hand there raises
  *Bad module qualification*.

  The `# Gloria ...` reasoning trace is written on `user_error` and therefore
  shows up next to the solution.
- Two platform details constrain the design (both checked against
  `ciao_playground.js` / `ciao-prolog.js`): the editor only supports the `.pl`,
  `.md` and `.lpdoc` extensions, and the uploaded path is
  `'/' + <name in the module directive> + '.pl'`.

### 8. Verify the glue natively
`load_agent_code/1` is exercised by `ciao/gloria/tests/t_playground.pl`, which
replays the same golden scenarios as the parity harness through the generated
`.pl` files, and by `query_rewriting/0`, which checks the page's
`disguise_trans_query/3` rewriting:

```bash
ciao run ciao/gloria/tests/run_unittests.pl   # t_engine + t_playground
```

### 9. Verify in a real browser
The page is a genuine playground: `init_queries` imports the engine and the
rewriting helper from the worker VFS, and a `ToplevelProc.prototype.trans_query`
patch wraps each top-level query in `disguise_trans_query/3` (see
`CIAO-PLAYGROUND-PROJECT.md` §5.2.1 for the design and the traps).

Drive it headlessly with Chrome + CDP (the harness used during development is
`/tmp/pg_gloria_e2e.js`; the essential steps are a hard reload, `Load ▶`, then
a `prolog_agent(...)` query):

```bash
google-chrome --headless=new --remote-debugging-port=9222 --user-data-dir=/tmp/chr-prof &
node /tmp/pg_gloria_e2e.js enclosure
```

Expected (same golden actions as the parity tests):

```
?- load_agent_code('/enclosure.pl').
yes
?- prolog_agent(enclosure, 0, 400, [time_day(am), it_is(sunny)], Actions).
Actions = [do(shut(east_window),0),do(open(doors),0)]
```

### 10. Full wasm build
```bash
ciao build --grade=wasm ciaowasm
ciao install --grade=wasm -x ciaowasm
ciao install --grade=wasm builder
ciao install --grade=wasm gloria
ciao custom_run ciao_playground dist
ciao custom_run ciao_playground dist_playground gloria
./serve_gloria.sh
```

(Emscripten must be on `PATH`; `ciao fetch lpdoc` is needed once for
`ciao_playground dist`.)

## 📋 Self-Hosted Testing Checklist (for this environment)

| Test | How to Run | Status |
|---|---|---|
| **Core engine** | `ciao run ciao/gloria/tests/run_unittests.pl` | ✅ 11/11 passed, `status=0` (4 engine + 7 playground glue) |
| **Parity** | `./ciao/gloria/tests/parity_scenarios_check.sh` | ✅ 6/6 agents |
| **Page validity** | `python3 playground/mkpage.py` then `node --check` on the page scripts | ✅ 6 example links, splash = enclosure agent |
| **Wasm bundle** | `ciao install --grade=wasm builder gloria` | ✅ Installed (emcc 6.0.10) |
| **Site** | `ciao custom_run ciao_playground dist dist_playground gloria` then `./serve_gloria.sh` | ✅ All assets 200 on `http://localhost:8000/playground/gloria.html` |
| **In-browser query** | Load ▶ then `prolog_agent(...)` in the top level | ✅ Verified headless (Chrome + CDP): `Actions = [do(shut(east_window),0),do(open(doors),0)]` |

## 🛠️ Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| `library(gloria/gloria)` not found in the page | Bundle not installed for the wasm grade, or the prebuilt engine predates the `alias_paths/1` in `Manifest/Manifest.pl` | `ciao install --grade=wasm gloria` (with emcc on `PATH`); note the prebuilt engine has no Gloria `library` aliases, which is why the page imports the sources by path |
| `{SYNTAX ERROR: Malformed query}` for every top-level query | The wrapped goal ends with a period; `query_one_begin` wants an unterminated goal | Do not append `.` in `pg_rewrite_goal` |
| `ReferenceError: toplevel is not defined` at boot | The `trans_query` patch was installed at `DOMContentLoaded`, before `lpdoc.js` imported `ToplevelProc` | Install it as soon as `ToplevelProc` exists (poll) |
| Page loads but nothing runs | Page assembled but not served from the site root | Serve `$CIAOROOT/build/site` (`./serve_gloria.sh`), not the repo |
| Agent not built after `Load ▶` | No `:- module(<agent>, ...)` at the top of the editor | Keep the module directive: it gives the agent its name (the file path becomes `/<agent>.pl`) |
| Wrong agent picked up | The editor's module name changed | The agent id *is* the module name; reload after renaming |
| `Load ▶` says the file is missing | The editor content was not uploaded | `load_agent_code` must be listed in `special_query` with `read_code: true` |
| Queries say *Bad module qualification* | `library(gloria/gloria)` is not imported into `user`, and `user` does not see the engine | Expected: the page rewrites Gloria goals into the `gloria` module in Prolog (`disguise_trans_query/3`). If it is not happening, check that the `install_disguise_trans_query` script is in the page |
| `serve_gloria.sh` falls back to Python | `mt-httpd.py` not found | Harmless fallback; keep the threaded server for wasm |
| ALD notebooks don't render | Browser may block `file:` URLs | Use the `http://localhost:8000/` server |

## 📦 What's Included in This Repo for Testing

```
gloria/
  Manifest/Manifest.pl          # bundle deps, builder hook for playground
  build.sh                       # local dev build/serve script
  COPYING                       # LGPL3 license text
  src/                          # engine files with :- module/2 headers
  examples/                      # original agent .g/.kb/.main files
  tests/                         # parity harness, unittest suite, scenarios
  playground/                    # page + generator + generated agents (WP3)
    gloria.html                  # GENERATED by mkpage.py - do not edit
    mkpage.py                    # generates gloria.html and agents/*.pl
    agents/*.pl                  # GENERATED self-contained agents (one per agent)
    alds/                        # 7 ALD notebooks (intro, enclosure, burocratin, gerente, arch, mylamp, rentin)
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