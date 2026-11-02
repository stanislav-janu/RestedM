# RestedM

- Brief, backlog and design plan: `docs/BRIEF.md`, `docs/STORIES.md`, `docs/DESIGN.md`.
- Design rules: `design/DESIGN-SYSTEM.md`. Use its tokens; never raw colors, radii, spacing or durations.
- Build the app with `./scripts/build.sh`, run tests with `swift test`.
- Snapshots of every page in light and dark: `scripts/snap.sh` writes `build/snapshots/<page>-<mode>.png` (seed data, no network). Read them before calling a UI change done.
- In-app checks: `scripts/selftest.sh` prints PASS/FAIL per check and exits 0 when all pass. Add a check for each new menu command or action.
