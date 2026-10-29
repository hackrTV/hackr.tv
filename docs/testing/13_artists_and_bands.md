---
title: Artist Pages + Band Directory
area: Music & Player
minutes: 15
---
# Artist Pages + Band Directory

## Steps — flagship artists

1. Visit `/thecyberpulse`. → Landing page renders with theming; nav
   dropdown lists the artist's sections.
2. Visit `/thecyberpulse/bio`. → Bio page renders. While logged in, this
   registers a bio view (feeds the `artist_bios_viewed_all`
   achievement) — no visible change required, just no errors.
3. Visit `/xeraen`. → The XERAEN console (2026-10-28): a left-anchored
   terminal screen like the home page — `XERAEN · OMNIWAVE GENESIS VECTOR
   · ● TRANSMITTING` bar, a status block (HANDLE / NETWORK / VOICE OF /
   SIGNAL / ORIGIN / RELEASES with the newest cataloged release and its
   date / INCOMING when a release is coming soon / STATUS), the three
   lore paragraphs, `// DESTINATIONS //` rows (`[BIO] [RELEASES] [VAULT]
   [TCP] [FNET]`) and a `>` prompt. Lines flick on; any key skips. `bio`
   Enter → `/xeraen/bio`. No glowing boxes, no centered hackr.tv ASCII.
4. Visit `/xeraen/bio`. → The same console shape as a long page: bar
   with `[<] XERAEN` / `[>] RELEASES`, `// SECTION //` rules instead of
   nested fieldsets, the transmitter readouts as key/value rows, LATEST
   TRANSMISSION as one track row (cover thumb, title, `► PLAY`; plays on
   the permanent player and repaints to `❚❚ PAUSE`), the closing quote,
   destinations and the prompt — which must NOT grab focus on load (Space
   still scrolls the page).
5. Play a track from an artist page. → Player works; navigate between
   artist pages → player survives (invariant).

## Steps — other artists + landing pages

6. Spot-check three more artist slugs (e.g. `/system-rot`,
   `/wavelength-zero`, `/voiceprint`). → Landing pages render with
   track lists.
7. Visit `/sector/x`. → Sector X page renders.

## Steps — band directory

8. Visit `/f/net`. → Band directory renders. OST-type artists (e.g.
   TR4X 4 H4X) must NOT appear here — bands only.
9. Open a band profile page. → Band page renders (config-driven layout,
   colors, members/links as configured).
10. Check `/the-pulse-grid` (band/canon page). → Renders.

## Steps — mobile variants

11. Load `/thecyberpulse` at a phone viewport. → Usable layout (the
    dedicated mobile views were retired with the SPA; responsive layout
    must hold).
