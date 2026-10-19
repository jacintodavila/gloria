#!/bin/sh
# serve_gloria.sh - build & serve the Ciao (wasm) playground for Gloria.
#
# The stock Ciao playground is assembled by the `ciao_playground` bundle
# into:
#
#     $CIAOROOT/build/site
#
# (see `ciao custom_run ciao_playground dist`).  This script serves that
# directory over HTTP.
#
# NOTE: this is the *Ciao/wasm* playground.  The separate SWI/Gloria web
# application under web/ is started by its own server and is deliberately
# not touched by this script.

set -e

PORT="${PORT:-8000}"

# --- locate CIAOROOT ---------------------------------------------------------
if [ -z "$CIAOROOT" ]; then
    for d in "$HOME"/.ciaoroot/*; do
        [ -d "$d/build/site" ] && CIAOROOT="$d"
    done
fi

if [ -z "$CIAOROOT" ]; then
    echo "ERROR: cannot find CIAOROOT (the Ciao install)." >&2
    echo "       Export CIAOROOT=/path/to/.ciaoroot/<version> and retry." >&2
    exit 1
fi

SITE="$CIAOROOT/build/site"

if [ ! -d "$SITE" ]; then
    cat >&2 <<EOF
ERROR: $SITE does not exist yet.

Build the playground first (with the Ciao environment on PATH and
Emscripten available for the wasm grade):

    export CIAOROOT=$CIAOROOT
    export PATH="\$CIAOROOT/build/bin:\$PATH"
    . /path/to/emsdk/emsdk_env.sh
    ciao install --grade=wasm -x ciaowasm
    ciao custom_run ciao_playground dist

EOF
    exit 1
fi

echo "Ciao playground site : $SITE"
echo "Open                 : http://localhost:$PORT/playground/"
echo "                       http://localhost:$PORT/playground/on-the-fly.html"

cd "$SITE"

MT_HTTPD="$HOME/.ciao/ciao_playground/etc/mt-httpd.py"
if [ -f "$MT_HTTPD" ]; then
    # threaded + CORS + .wasm mime (recommended for wasm apps)
    echo "Server               : mt-httpd.py (threaded, application/wasm)"
    exec python3 "$MT_HTTPD" "$PORT"
else
    echo "Server               : python3 -m http.server (threaded fallback)"
    exec python3 -m http.server "$PORT"
fi
