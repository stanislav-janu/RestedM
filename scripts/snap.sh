#!/bin/zsh
# Snapshots of every page in light and dark with seed data, no network:
#   build/snapshots/<page>-light.png and <page>-dark.png
# Usage: scripts/snap.sh
#        RESTEDM_SNAPSHOT_PAGES=response-body,settings scripts/snap.sh
# Run it from a terminal (or Claude) that has Screen Recording permission.
set -u
cd "${0:A:h}/.."
app=build/RestedM.app/Contents/MacOS/RestedM
shots=$PWD/build/snapshots
pkill -x RestedM
while pgrep -x RestedM >/dev/null; do sleep 0.2; done
rm -rf $shots
# Fixed display settings in the argument domain, so the user's own defaults stay untouched.
RESTEDM_SNAPSHOT=$shots $app -ApplePersistenceIgnoreState YES \
  -prettyPrint YES -highlightSyntax YES -includeLineNumbers NO -defaultResponseTab 0 -paramBodyUIChoice 0
