#!/bin/sh
# parity_scenarios_check.sh -- run every example-agent scenario under both
# engines (SWI vs Ciao) and diff the canonicalized per-step actions.
# Run it from anywhere:  ./ciao/gloria/tests/parity_scenarios_check.sh
# Exit 0 iff every scenario matches.
#
# Overridable from the environment:
#   SWIPL  -- the swipl binary  (default: swipl on $PATH)
#   CIAO   -- the ciao binary  (default: ciao on $PATH, else a Ciao
#             install under ~/.ciaoroot)
set -e

# Repository root: derived from this script's own location, not from $PWD.
# (this file lives in ciao/gloria/tests/, three levels below the root)
root=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)

# The Ciao drivers refer to the example agents by their repo-relative
# path, so run everything from the repository root.
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
fail=0

run_one() {
    agent="$1"; kb="$2"; steps="$3"
    printf 'SCENARIO %-12s %s -> ' "$agent" "$steps"
    stepsfile="$tmp/steps_$agent.pl"
    printf '%s.\n' "$steps" > "$stepsfile"
    "$SWIPL" -q -g run_scenario "$root/ciao/gloria/tests/driver_scenario_s.pl" -- \
        "$agent" "$root/$kb" "$stepsfile" 2>/dev/null \
        > "$tmp/scen_s_$agent.txt" || true
    ( export PATH="$(dirname -- "$CIAOBIN"):$PATH"; timeout 120 "$CIAOBIN" run \
        "$root/ciao/gloria/tests/driver_scenario_c.pl" \
        "$agent" "$root/$kb" "$stepsfile" < /dev/null 2>/dev/null ) \
        > "$tmp/scen_c_$agent.txt" || true
    grep '^S ' "$tmp/scen_s_$agent.txt" > "$tmp/scen_s_$agent.shape" || true
    grep '^S ' "$tmp/scen_c_$agent.txt" > "$tmp/scen_c_$agent.shape" || true
    if diff -q "$tmp/scen_s_$agent.shape" "$tmp/scen_c_$agent.shape" >/dev/null; then
        echo "PARITY: OK"
        grep '^R ' "$tmp/scen_s_$agent.txt" | sed 's/^R //' | nl
    else
        echo "PARITY: DIVERGED"
        diff -u "$tmp/scen_s_$agent.shape" "$tmp/scen_c_$agent.shape" | head -20
        fail=1
    fi
}

run_one enclosure  examples/enclosure/enclosure.kb \
    '[[time_day(am),it_is(sunny)],[time_day(pm),it_is(rainy)]]'
run_one burocratin examples/burocratin/burocratin.kb \
    '[[me_pide(juan,sacar_constancia)]]'
run_one gerente    examples/gerente/gerente.kb \
    '[[timing(1),cola_larga],[timing(2),taq_vacias]]'
run_one arch       examples/arch/ex-arch.kb \
    '[[build(5),c(5),c(8),b(10)]]'
run_one mylamp     examples/mylamp/mylamp.kb \
    '[[motion(room)]]'
run_one rentin     examples/rentin/rentin.kb \
    '[[flojera,gano,no_hay_jueces_confiables,sin_observador],[flojera,gano,no_hay_jueces_confiables,observador_independiente]]'

exit $fail
