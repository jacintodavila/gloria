#!/bin/sh
# parity_scenarios_check.sh -- run every example-agent scenario under both
# engines (SWI vs Ciao) and diff the canonicalized per-step actions.
# Run from the repo root.  Exit 0 iff every scenario matches.
set -e
root="$(pwd)"
SWIPL=/home/jacinto/bin/swipl
CIAOPATH="$HOME/.ciaoroot/v1.25.0-m1/build/bin"
tmp=/tmp/opencode
fail=0

run_one() {
    agent="$1"; kb="$2"; steps="$3"
    printf 'SCENARIO %-12s %s -> ' "$agent" "$steps"
    stepsfile="$tmp/steps_$agent.pl"
    printf '%s.\n' "$steps" > "$stepsfile"
    "$SWIPL" -q -g run_scenario "$root/ciao/gloria/tests/driver_scenario_s.pl" -- \
        "$agent" "$root/$kb" "$stepsfile" 2>/dev/null \
        > "$tmp/scen_s_$agent.txt" || true
    ( export PATH="$CIAOPATH:$PATH"; timeout 120 ciao run \
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

exit $fail