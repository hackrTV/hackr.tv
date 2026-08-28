# hackr.tv Manual Testing Guide

A complete manual test pass over every feature of hackr.tv — public site,
THE PULSE GRID, and the `/root` admin — written as step-by-step articles.

## Three ways to use it

1. **Wizard** — `/root/test_guide` → START TEST RUN. Walks you through every
   article in order, records PASS / FAIL / BLOCKED / SKIP per article with
   notes, and shows a progress dashboard. Per-step checkboxes persist in
   your browser per run.
2. **Browse** — `/root/test_guide` lists all articles grouped by area
   (Handbook-style). Open any article directly for targeted re-testing.
3. **Offline** — read these files straight from `docs/testing/`. Filenames
   are ordered (`NN_slug.md`); frontmatter carries title, area, and a time
   estimate.

## Structure

| Range | Area |
|-------|------|
| 00–02 | Setup + cross-cutting invariants |
| 10–15 | Music platform + audio player |
| 20–23 | Social, comms, content pages |
| 30–39 | THE PULSE GRID |
| 40–49 | `/root` admin |
| 50–51 | External integrations + API spot checks |

A full pass takes roughly a working day. The wizard order front-loads
setup, then public surface, then grid, then admin, so early failures
surface before you invest in the long grid sections.

## Conventions used in the articles

- `→` means "expect to see / expect to happen".
- **Two-browser steps** need a second session (different browser or
  private window) — used for chat, presence, and broadcast tests.
- Terminal commands are typed into the Grid terminal exactly as shown.
- Articles are self-contained but assume `01_environment_setup` ran once.
