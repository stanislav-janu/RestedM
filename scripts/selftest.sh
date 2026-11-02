#!/bin/zsh
# Checks inside the running app with seed data, no network. Exits 0 when every check passes.
# Usage: scripts/selftest.sh
set -u
cd "${0:A:h}/.."
app=build/RestedM.app/Contents/MacOS/RestedM
# Runs as its own process next to any RestedM in use, which it never quits.
RESTEDM_SELFTEST=1 $app -ApplePersistenceIgnoreState YES &
pid=$!
# Focus checks need a key window. macOS keeps an app started from a shell in the background,
# so bring this process (by id, not the RestedM in use) forward while the checks run.
for i in {1..40}; do
  kill -0 $pid 2>/dev/null || break
  osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $pid) to true" >/dev/null 2>&1
  sleep 0.5
done
wait $pid
