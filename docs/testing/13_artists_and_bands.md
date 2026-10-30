---
title: Artist Pages + Band Directory
area: Music & Player
minutes: 20
---
# Artist Pages + Band Directory

## Steps — flagship artists

1. Visit `/thecyberpulse`. → The.CyberPul.se console (2026-10-29, the
   XERAEN console's twin — step 3): `THE.CYBERPUL.SE · TRANSMISSION
   ORIGIN & BROADCAST HUB · ● BROADCASTING` bar, a status block (HOSTS /
   NETWORK / ORIGIN / FORMAT / RELEASES with the newest cataloged release
   / INCOMING when one is coming soon / VIDZ with the newest recording /
   STATUS), the three lore paragraphs, `// DESTINATIONS //` rows (`[BIO]
   [RELEASES] [VIDZ] [VAULT] [GRID] [XERAEN] [FNET]`) and a `>` prompt.
   Lines flick on; any key skips; `vidz` Enter → `/thecyberpulse/vidz`.
   The nav dropdown still lists the artist's sections.
2. Visit `/thecyberpulse/bio`. → The same console shape as a long page:
   `[<] TCP` / `[>] RELEASES` bar links, `// SIGNAL INCOMING //` through
   `// LAST WORDS //` rules instead of the stacked fieldsets, the newest
   VOD embedded under `// VISUAL TRANSMISSION //` (omitted when there is
   none), THE PULSE GRID readouts as key/value rows, destinations and the
   prompt (which must NOT grab focus on load). While logged in, this
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
5. Visit `/xeraen/releases` and open a release. → The catalog console
   (2026-10-29, XERAEN and The.CyberPul.se — every other band still gets
   the card grid, article 14; `/thecyberpulse/releases` and its tracks
   are the same screens with `[<] TCP`): the index is a ledger — bar with
   `[<] XERAEN` / `[>] VAULT`, CATALOG / LATEST / INCOMING rows, then
   `// INCOMING //` and `// CATALOG //` rules with one row per release
   (`[01]`, a 40px cover, the name, `TYPE · date · n tracks · length`);
   typing a row's number at the prompt opens it. The release page: bar
   (name · `XERAEN · EP`, `[<] RELEASES` / `[>] VAULT`), the cover beside
   ARTIST / TYPE / RELEASED / LABEL / TRACKS rows, `// TRACKS //` rows
   (`01 Title … 2:44 ► PLAY`; plays on the permanent player and repaints
   to `❚❚ PAUSE`; the title opens the track page), `// FREQUENCIES //`
   as `[LISTEN] [YT] [SP] …` rows, destinations, the prompt. A
   coming-soon release shows `◌ SIGNAL INCOMING`, masked tracks and
   `NOT YET ALLOCATED`; an unknown slug shows `// SIGNAL LOST //` with a
   404. Open a track from the list: the track page is the same screen —
   bar (title · `XERAEN · TRACK 02`, `★ FEATURED` when featured,
   `[<] XORDIUM` / `[>] VAULT`), the cover beside ARTIST / RELEASE / TRACK
   (`02 of 03`) / RELEASED / LENGTH rows, `// TRANSMISSION //` as one
   player row (► PLAY works), `// DECODED LYRICS //`, `// FREQUENCIES //`
   (`[LISTEN] [SP] [AM] [YT]`, plus `[VOD]` rows when a recording is
   attached), `// ALSO ON XORDIUM //` sibling rows (their numbers work at
   the prompt). A coming-soon track still redirects to its release; an
   unknown slug is `// SIGNAL LOST //` with a 404. A single (one released
   track — `/xeraen/trackz/encrypted-shroud`) has no release screen: its
   ledger row and the landing's LATEST link open the track page, which
   folds in the release's LABEL / CATALOG # rows, `// DESCRIPTION //`,
   `// CREDITS //`, `// NOTES //` and its frequencies, with `[<] RELEASES`
   in the bar and no TRACK `01 of 01` row;
   `/xeraen/releases/encrypted-shroud` redirects there. Rest the pointer
   on any cover (a ledger thumb, the release / track cover, the bio's track
   row): a larger rendition opens beside it and closes on leaving; a
   touch screen gets no peek, the thumb stays a plain link.
6. Play a track from an artist page. → Player works; navigate between
   artist pages → player survives (invariant).

## Steps — other artists + landing pages

7. Spot-check three more artist slugs (e.g. `/system-rot`,
   `/wavelength-zero`, `/voiceprint`). → Landing pages render with
   track lists.
8. Visit `/sector/x`. → Sector X page renders.

## Steps — band directory

9. Visit `/f/net`. → Band directory renders. OST-type artists (e.g.
   TR4X 4 H4X) must NOT appear here — bands only.
10. Open a band profile page. → Band page renders (config-driven layout,
   colors, members/links as configured).
11. Check `/the-pulse-grid` (band/canon page). → Renders.

## Steps — mobile variants

12. Load `/thecyberpulse` at a phone viewport. → Usable layout (the
    dedicated mobile views were retired with the SPA; responsive layout
    must hold).
