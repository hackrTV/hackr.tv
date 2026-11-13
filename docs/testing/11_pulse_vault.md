---
title: Pulse Vault
area: Music & Player
minutes: 10
---
# Pulse Vault (/vault)

## Steps

1. Visit `/vault`. → Track table renders with artists, titles, durations,
   cover art; artist filter/sections present. Heading reads `ALL TRACKS`.
   From a band profile, the Coming Soon screen or a console catalog,
   follow its vault link (`/vault?artist=<slug>`) → heading carries the
   artist's name, only that artist's tracks are listed (an artist named
   "Offline" does not pull in other artists' "offline" titles), the
   infobox offers `[x] ALL TRACKS` back to the full vault; the search box
   still filters within. `?filter=<text>` keeps pre-filling the search box.
2. Click a track row. → Player starts it; row indicates the playing
   track; player bar shows title/artist/cover.
3. Let the track end (pick a short one, or seek near the end). → Queue
   auto-advances to the next vault track; player keeps playing.
4. Click a DIFFERENT artist's track mid-playback. → Playback switches
   immediately, no error, cover/title update.
5. Hidden tracks: any track flagged out of the vault
   (`show_in_pulse_vault: false`) must NOT appear. Cross-check one such
   track exists via admin → Tracks.
6. **Add to playlist**: use the add-to-playlist control on a row →
   choose/create a playlist. → Confirmation; the track shows up under
   `/fm` → your playlist.
7. Logged-out check (second browser, logged out): `/vault` renders and
   plays; playlist-add prompts for login or is hidden.
8. Play credit: play one full short track; later confirm the play
   registered (admin analytics or the track's play count if displayed).
