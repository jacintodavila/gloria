#!/bin/sh
# parity_check.sh -- run both engines on the enclosure example and diff
# the canonicalized Actions/NextGs/OutGs.  Run from the repo root.
set -e
root="$(pwd)"
SWIOUT="$(/home/jacinto/bin/swipl -q -g run_parity -f none "$root/ciao/gloria/tests/driver_parity_s.pl" 2>/dev/null || true)"
CIAOOUT="$(export PATH="$HOME/.ciaoroot/v1.25.0-m1/build/bin:$PATH"; timeout 120 ciao run "$root/ciao/gloria/tests/driver_parity_c.pl" < /dev/null 2>/dev/null || true)"
printf '%s\n' "$SWIOUT"   > /tmp/opencode/parity_swi.txt
printf '%s\n' "$CIAOOUT"  > /tmp/opencode/parity_ciao.txt
if diff -u /tmp/opencode/parity_swi.txt /tmp/opencode/parity_ciao.txt > /tmp/opencode/parity.diff; then
    echo "PARITY: OK (SWI == Ciao)"
else
    echo "PARITY: DIVERGED -- see /tmp/opencode/parity.diff"
    sed -n '1,40p' /tmp/opencode/parity.diff
    exit 1
fi