#!/bin/sh
# run_unittests.sh -- run the Ciao unittest suite for the ported Gloria engine.
# Usage: ciao/gloria/tests/run_unittests.sh  (from the repo root)
set -eu
export PATH="$HOME/.ciaoroot/v1.25.0-m1/build/bin:$PATH"
cd "$(dirname "$0")/../../.."   # repo root
ciao run ciao/gloria/tests/run_unittests.pl