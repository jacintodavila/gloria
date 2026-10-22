#!/bin/sh
# parity_check.sh -- run both engines on the enclosure example and diff
# the canonicalized Actions/NextGs/OutGs.
# Run it from anywhere:  ./ciao/gloria/tests/parity_check.sh
#
# Overridable from the environment:
#   SWIPL  -- the swipl binary  (default: swipl on $PATH)
#   CIAO   -- the ciao binary  (default: ciao on $PATH, else a Ciao
#             install under ~/.ciaoroot)
set -e

# Repository root: derived from this script's own location, not from $PWD.
# (this file lives in ciao/gloria/tests/, three levels below the root)
root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)

# The Ciao driver refers to the example agent by its repo-relative path,
# so run everything from the repository root.
cd "$root"

# SWI-Prolog interpreter.
SWIPL="${SWIPL:-swipl}"
if ! command -v "$SWIPL" >/dev/null 2>&1; then
    echo "ERROR: swipl not found -- set \$SWIPL to its path" >&2
    exit 1
fi

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

# Scratch space for the intermediate files.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

SWIOUT="$("$SWIPL" -q -g run_parity -f none "$root/ciao/gloria/tests/driver_parity_s.pl" 2>/dev/null || true)"
CIAOOUT="$(export PATH="$(dirname -- "$CIAOBIN"):$PATH"; timeout 120 "$CIAOBIN" run "$root/ciao/gloria/tests/driver_parity_c.pl" < /dev/null 2>/dev/null || true)"
printf '%s\n' "$SWIOUT"  > "$tmp/parity_swi.txt"
printf '%s\n' "$CIAOOUT" > "$tmp/parity_ciao.txt"
if diff -u "$tmp/parity_swi.txt" "$tmp/parity_ciao.txt" > "$tmp/parity.diff"; then
    echo "PARITY: OK (SWI == Ciao)"
else
    echo "PARITY: DIVERGED -- first differences:"
    sed -n '1,40p' "$tmp/parity.diff"
    exit 1
fi
