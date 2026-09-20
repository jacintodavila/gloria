#!/bin/sh
# build.sh — local development build/serve for the gloria Ciao bundle.
# See: CIAO-PLAYGROUND-PROJECT.md §6.1

# Check/compile the ported engine (native Ciao)
ciao build --bin gloria

# Wasm build grade for browser use (requires ciaowasm/emscripten)
# ciao install --grade=wasm gloria

# Assemble the build/site (copies html, js, etc. to the ciao_playground build dir)
# ciao custom_run ciao_playground dist

# Copy the gloria playground page into /playground/
# ciao custom_run ciao_playground dist_playground gloria

# Serve with the multi-threaded server (single-threaded servers may deadlock
# when loading wasm in some browsers)
# ciao-serve-mt

# Browse the playground:
# http://localhost:8001/playground/gloria.html