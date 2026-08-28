---
title: Cross-Cutting Invariants
area: Setup
minutes: 15
---
# Cross-Cutting Invariants

Behaviors that must hold EVERYWHERE. Test them once deliberately here;
then keep watching for them during every later article.

## Permanent audio player

1. Log in as the operative, open `/vault`, click a track. → Player bar
   at the bottom starts playing.
2. Navigate via the top nav through at least: home (`/`), `/wire`,
   `/feed`, `/uplink`, an artist page, `/fm`, `/schedule`, `/codex`,
   `/grid`. → Audio NEVER stops or stutters; the player bar stays put;
   pages swap without a full reload (no favicon flash / spinner).
3. Open `/grid/1337`, then navigate back out to `/vault`. → Still
   playing.
4. Full-reload exception: log out and back in. → A session change IS a
   full page load (player resets) — that's correct.

## Toasts

5. While the operative is anywhere on the site, award them an
   achievement from the admin browser (`/root` Grid → Achievements →
   pick a manual one → award to the operative; or grant via a
   gameplay action you know unlocks one). → A toast slides into the
   corner in the operative's browser WITHOUT reloading, showing the
   achievement name and rewards.

## Terminal easter egg

6. On any main-site page press `Ctrl+` ` (backtick). → The terminal
   overlay opens with the retro terminal inside an iframe. `ESC` closes.
7. Enter the Konami code (↑↑↓↓←→←→BA). → Same overlay opens.
8. Type `/terminal` anywhere (not in an input). → Same overlay opens.

## Error pages + chrome

9. Visit a garbage URL like `/definitely-not-a-page`. → Styled 404 page,
   HTTP 404 (check the network tab), no stack trace.
10. Check the favicon + tab title on a few pages. → Present and correct.
11. Spot-check one page (e.g. `/vault`) at a phone-ish viewport
    (~390px). → Layout usable, nav accessible, player reachable.

## Flash + auth gating

12. Log out, then try `/identity` directly. → Redirected to grid login.
13. As a NON-admin (operative), try `/root`. → Denied (redirect or 404),
    never the admin UI.
