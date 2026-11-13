---
title: Artist Catalog — Releases, Trackz, Vidz
area: Music & Player
minutes: 15
---
# Artist Catalog (releases / trackz / vidz)

## Steps — releases

1. Visit `/system-rot/releases` (any band outside the console — XERAEN's
   and The.CyberPul.se's catalogs are the console, article 13 step 5). →
   Release index for the artist: released grid + coming-soon strip;
   registers a release-index view (achievement source) silently. Any
   artist in the DB resolves here, not only the routed slug list
   (`/synthia/releases`, article 13 step 12); an unknown slug 404s.
2. Open a release (`/system-rot/releases/<slug>`). → Detail page:
   cover, track list, disc length; play works.
3. A release whose tracks are all vault-hidden must 404 here; a
   coming-soon release renders but does not play. A release under
   another artist's slug (`/system-rot/releases/<an XERAEN release
   slug>`) → SIGNAL LOST 404, never the foreign release; same for
   `/<artist>/trackz/<another artist's track>`.
4. Numeric-id URL for the same release. → Also resolves (slug-or-id),
   still only within that artist's catalog.

## Steps — trackz

5. Open a track page (`/<artist>/trackz/<slug>`). → Track detail renders
   (cover, release link, duration); play works. (XERAEN's and
   The.CyberPul.se's track pages are the console — article 13 step 5.)
6. A track belonging to a coming-soon release. → Redirects to the
   release page instead of rendering.
7. Legacy `/trackz/:id` URL (old bookmark shape). → Redirects to the
   canonical artist-scoped page of the track's own artist (try a XERAEN
   track slug → `/xeraen/trackz/<slug>`); an unknown slug lands on
   `/thecyberpulse/trackz/<slug>` SIGNAL LOST.

## Steps — vidz (VODs)

8. Visit `/thecyberpulse/vidz`. → The VIDZ archive as a console screen
   (2026-10-29): `THE.CYBERPUL.SE · VIDZ · VISUAL TRANSMISSIONS` bar with
   `[<] TCP` / `[>] SCHEDULE`, ARCHIVE / LATEST rows, then `// ARCHIVE //`
   rows (`[01]`, a 64px YouTube thumb, the title, `date · artist ·
   LIVESTREAM`) — TCP's and XERAEN's streams that have a vod_url (no
   other artist's appear). Typing a row's number at the prompt opens it;
   an empty archive reads `NO RECORDINGS ARCHIVED YET`. Hovering a thumb
   opens the full-size frame beside it.
9. Open a VOD. → `/thecyberpulse/vidz/<id>`: bar (title · `THE.CYBERPUL.SE
   · VIDZ`, `● LIVESTREAM` badge when it was one, `[<] VIDZ`), ARTIST /
   RECORDED / FORMAT rows, `// PLAYBACK //` with the click-to-play embed,
   `// ALSO IN THE ARCHIVE //` rows (their numbers work at the prompt),
   destinations. While logged in, playing credits a VOD watch (feeds
   `vods_watched`) via the watch ping — check the network tab for the
   `POST /api/artists/<the stream's artist>/vods/<id>/watch` beacon
   (`xeraen` for an XERAEN recording). An unknown id is
   `// SIGNAL LOST //` with a 404.
10. Visit `/xeraen/vidz` and `/xeraen/vidz/<id>`. → Both redirect onto
    `/thecyberpulse/vidz…`; an XERAEN recording's page loads there.
11. From `/schedule`, click a past stream's `[VOD]` link. → Lands on the
    vidz page via Turbo (player survives).
