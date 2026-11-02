#!/bin/zsh
# Checks inside the running app with seed data, no network. Exits 0 when every check passes.
# Usage: scripts/selftest.sh
set -u
cd "${0:A:h}/.."
app=build/RestedM.app/Contents/MacOS/RestedM
# Runs as its own process next to any RestedM in use, which it never quits or activates.
RESTEDM_SELFTEST=1 $app -ApplePersistenceIgnoreState YES
