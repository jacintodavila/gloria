#!/bin/sh
# run_unittests.sh -- run the Ciao unittest suite for the ported Gloria engine.
# Usage: ciao/gloria/tests/run_unittests.sh  (from anywhere)
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
cd "$root"

# Ciao interpreter: prefer the one on $PATH, else the newest install
# under ~/.ciaoroot (the glob expands in ascending order, so the last
# match is the newest).
CIAO="${CIAO:-ciao}"
if ! CIAOBIN=$(command -v "$CIAO" 2>/dev/null); then
    CIAOBIN=""
    for d in "$HOME"/.ciaoroot/*; do
        if [ -x "$d/build/bin/ciao" ]; then
            CIAOBIN="$d/build/bin/ciao"
        fi
    done
fi
if [ -z "$CIAOBIN" ]; then
    echo "ERROR: ciao not found -- set \$CIAO to its path" >&2
    exit 1
fi
export PATH="$(dirname -- "$CIAOBIN"):$PATH"

"$CIAOBIN" run ciao/gloria/tests/run_unittests.pl
