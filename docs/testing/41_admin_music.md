---
title: Admin — Music Catalog
area: Admin
minutes: 25
---
# Admin — Artists, Releases, Tracks, Radio

The music section of `/root` is a set of console screens (the home /
XERAEN / TCP console idiom: a bar, status rows, `// RULES //`, aligned
`[TAG]` rows, the `>` prompt). The record screen IS the edit screen —
the status rows hold the fields, the prose sections are textareas, the
commit row is the console's ghost buttons. Catalog data is DB-backed
(YAML seeds only create); every change below is reversible — restore
what you touch.

## Steps — artists

1. `/root` → Music → Artists. → The ARTISTS console: ON RECORD / CATALOG
   readouts, `// ARTISTS //` rows (`[NN]` · name over slug · TYPE · genre
   · releases · tracks · `[EDIT] [HISTORY]`), destinations, the prompt.
   Type a row's number at the prompt + Enter. → The artist's record
   screen opens (a full page load; the admin has no Turbo).
2. On the record: NAME / SLUG / TYPE / GENRE rows, `// COMMIT //`,
   `// RELEASES //` rows for the artist + `[+] NEW RELEASE`. Change GENRE,
   `[SAVE ARTIST]`. → Stays on the record with `[OK] Artist '…' updated.`;
   `[HISTORY]` lists the change. Restore the genre.
3. Blank the NAME and save. → `[ERR]` reply, the form re-renders on the
   saved slug (no 404 / no broken action). `[CANCEL]` leaves.
4. `[DELETE ARTIST]` shows only for an artist with no releases or tracks
   (otherwise `DELETE LOCKED`). `[>] PUBLIC` shows only for an artist
   whose slug has public catalog routes (XERAEN, TCP, the bands).

## Steps — releases

5. Music → Releases. → One `// ARTIST · N RELEASES //` rule per artist,
   rows `[NN]` · cover thumb (hover → the large peek) · name over TYPE ·
   date · tracks · length · catalog # · slug, a state word (LIVE /
   INCOMING / HIDDEN = every track out of the vault) and `[HISTORY]`;
   LATEST / INCOMING readouts above. Open one by number or click.
6. The release record: the cover column (`[^] REPLACE COVER` picks a
   file — the name echoes beside the button, nothing uploads until SAVE;
   `[x] REMOVE COVER` confirms then purges at once), NAME … CLASS rows,
   STATUS = the `◌ SIGNAL INCOMING` checkbox, `// DESCRIPTION //`
   `// CREDITS //` `// NOTES //` textareas that grow with their text,
   `// FREQUENCIES //` = one URL field per platform (BC YT SP AM SC;
   blank rows are dropped, all blank = nil so the public page aggregates
   the tracks' links), `// COMMIT //`, then `// TRACKS //` rows (`NN` ·
   title over slug · AUDIO / NO AUDIO · ★ · VAULT / HIDDEN · time ·
   `[HISTORY] [DEL]`) + `[+] ADD TRACK`.
7. Edit a frequency URL and save. → Stays on the record, `[OK]`; the
   public release page (`[>] PUBLIC`) shows the link. Restore it.
8. Toggle `◌ SIGNAL INCOMING` on a release, save, check the public
   catalog (tracklist encrypted, the vault drops its tracks), then
   RESTORE.
9. `[DELETE RELEASE + N TRACKS]` asks you to TYPE the slug (Cancel
   cancels; a wrong slug says so and keeps the record). Do not confirm
   on real data — create a throwaway release via `[+] NEW RELEASE` (the
   ARTIST select is prefilled when you come from an artist screen),
   add a track to it, then delete it from its record screen.

## Steps — tracks

10. Music → Tracks. → ON RECORD readouts, the FILTER row (type part of a
    title / slug / artist / release — rows and whole release groups that
    miss it hide, the count reads shown / total, `[x] CLEAR` resets),
    one `// ARTIST · RELEASE (TYPE) //` rule per release.
11. Open a track. → The track record: the release's cover for context,
    TITLE / SLUG / RELEASE (grouped by artist — the artist follows the
    release) / TRACK # / LENGTH / RELEASED / FLAGS (★ FEATURED, IN THE
    VAULT) / AUDIO (ON FILE + an inline player + `[^] REPLACE AUDIO` ·
    `[x] REMOVE AUDIO`, or NO AUDIO ON FILE + `[^] UPLOAD AUDIO`),
    `// DECODED LYRICS //` = one tall textarea, `// FREQUENCIES //`,
    `// COMMIT //`, `// ALSO ON <RELEASE> //` = the release's other tracks
    (type a number at the prompt to hop to one).
12. Edit the lyrics (add a line), `[SAVE TRACK]`. → Stays on the track
    with `[OK]`; `[>] PUBLIC` shows the line under `// DECODED LYRICS //`
    on the console artists. Restore.
13. Toggle IN THE VAULT off, save, verify on `/vault` (the track is
    gone), then RESTORE.
14. `[+] ADD TRACK` from a release record. → NEW TRACK with the RELEASE
    preselected and TRACK # = the next number; `[CREATE TRACK]` opens
    the new track's own record (not the release). Delete it from there
    (`[DELETE TRACK]` → confirm) — lands back on the release.

## Steps — radio

15. Radio (destinations `[RADIO]` or Music → Radio) → stations index with
    playlists (still the table layout). Edit a station's playlist
    assignment; verify `/fm/radio` reflects it; restore.
16. Redirects (Meta → Redirects): create a test redirect, hit the source
    path in the public site → lands on the target; delete the test
    redirect.

## Cleanup

Restore anything you changed; note irreversible edits in the run notes.
