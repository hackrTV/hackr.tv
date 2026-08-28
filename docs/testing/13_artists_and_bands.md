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
3. Visit `/xeraen` + `/xeraen/bio`. → Same shape, different theming.
4. Play a track from an artist page. → Player works; navigate between
   artist pages → player survives (invariant).

## Steps — other artists + landing pages

5. Spot-check three more artist slugs (e.g. `/system-rot`,
   `/wavelength-zero`, `/voiceprint`). → Landing pages render with
   track lists.
6. Visit `/sector/x`. → Sector X page renders.

## Steps — band directory

7. Visit `/f/net`. → Band directory renders. OST-type artists (e.g.
   TR4X 4 H4X) must NOT appear here — bands only.
8. Open a band profile page. → Band page renders (config-driven layout,
   colors, members/links as configured).
9. Check `/the-pulse-grid` (band/canon page). → Renders.

## Steps — mobile variants

10. Load `/thecyberpulse` at a phone viewport. → Usable layout (the
    dedicated mobile views were retired with the SPA; responsive layout
    must hold).
