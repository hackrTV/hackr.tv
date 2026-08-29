---
title: Test Environment Setup
area: Setup
minutes: 15
---
# Test Environment Setup

Everything the later articles assume. Do this once per run.

## Accounts

You need three Grid Hackr accounts:

1. **Admin** — your normal admin account (role admin; sees `/root`).
2. **Operative** — a regular account with `pulse_grid` + `tactical_grid`
   feature grants, tutorial completed, some CRED, a deck, and a few
   inventory items. This is the main test identity.
3. **Fresh** — a brand-new account you will REGISTER during
   `30_grid_auth` and run the tutorial with in `32_grid_tutorial`. Have
   an email inbox you can read for it (mailcatcher/letter_opener in dev;
   a real inbox on staging).

## Steps

1. Boot the app (`bin/dev` locally) and log in as the admin. → `/root`
   dashboard loads.
2. In `/root` → Hackrs: confirm the operative exists, is NOT
   login-disabled, and holds `pulse_grid` and `tactical_grid` grants.
   Grant them if missing.
3. Confirm world data is seeded: `/root` Grid → Zones shows zones/rooms;
   Item Defs, Missions, Breach Templates, Transit Routes are non-empty.
   → All lists populated. (Empty world = run `rails data:load` before
   continuing.)
4. Confirm music data: `/vault` shows tracks with cover art; at least one
   playlist exists; at least one radio station configured.
5. Confirm at least one NPC vendor, one quest-giver mob with an
   available mission, one rest pod room, and one transit-stop room exist
   reachable near the operative's current room (Grid → Mobs / Rooms; use
   the Map Editor to look around). Note their locations for the grid
   articles.
6. Open a second browser and log in as the operative (keep the admin in
   the first). → Both sessions live side by side.
7. Sanity-check mail delivery for the fresh-account flow: trigger any
   mailer (e.g. request a password reset for the operative) and confirm
   you can read the email. → Email arrives and renders.

## Record in the run notes

- Environment (local/staging/prod) + git SHA (`git rev-parse --short HEAD`).
- The three account aliases.
- Locations noted in step 5 (vendor / quest giver / rest pod / transit).
