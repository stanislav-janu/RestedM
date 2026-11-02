#!/bin/zsh
# Checks inside the running app with seed data, no network. Exits 0 when every check passes.
# Usage: scripts/selftest.sh
set -u
cd "${0:A:h}/.."
app=build/RestedM.app/Contents/MacOS/RestedM
pkill -x RestedM
while pgrep -x RestedM >/dev/null; do sleep 0.2; done
RESTEDM_SELFTEST=1 $app -ApplePersistenceIgnoreState YES
