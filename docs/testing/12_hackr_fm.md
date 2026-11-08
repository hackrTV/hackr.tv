---
title: hackr.fm — Radio, Releases, Playlists
area: Music & Player
minutes: 25
---
# hackr.fm (/fm)

## Steps — landing + releases

1. Visit `/fm`. → A left-anchored console screen (no centered ASCII
   banner): bar `HACKR.FM · MUSIC LABEL & BROADCAST NETWORK` with
   `● ON AIR`, `[>] RADIO`, `[>] VAULT`; status rows LABEL / SIGNAL /
   CATALOG (links `/fm/releases`) / INCOMING / ARTISTS (links `/f/net`) /
   STATUS; `// THE FREQUENCY //` lore in three tones; `// LATEST
   RELEASES //` as up to three `[NN]` tiles (120px cover, purple name,
   artist, `TYPE · date · n tracks`) and an `[>] All releases` row. Cover
   variants load — a broken image here historically means the libvips
   variant pipeline, see gotchas. Hover a cover → the large peek opens
   beside it.
2. Same page, `// TRANSMISSION INCOMING //` (only with coming-soon
   releases). → Tiles whose covers keep the animated look: glowing frame,
   moving scanlines, tint, `INCOMING` badge, a glitch on hover;
   `PENDING TRANSMISSION` in the meta line. Past four, the rest are
   hidden. Triple-click the pulsing `// TRANSMISSION INCOMING //` title
   → the code prompt opens; a valid code reveals the hidden tiles, a
   wrong one shows `AUTHORIZATION DENIED`.
3. Same page, bottom. → `// DESTINATIONS //` RADIO (red tag) / RELEASES
   / VAULT (purple) / FNET (green) / PLAYLISTS (logged in only) / HOME,
   then the `>` prompt. Type `02` + Enter → that release opens; type
   `fnet` → `/f/net`; `?` lists the commands.
4. Visit `/fm/releases`. → Console screen, bar `[<] FM` / `[>] VAULT`,
   CATALOG (releases · tracks · artists) and LATEST rows, `// CATALOG //`
   of numbered tiles newest first with catalog numbers; a release without
   a cover shows a `♪` box. Coming-soon releases are NOT listed.
5. Open a release. → Track list with numbers/durations; disc length;
   clicking a track plays it and queues the release order.
6. Repeat steps 1 and 4 at a phone viewport. → Tiles shrink to 80px
   covers with the text beside them; nothing scrolls sideways.

## Steps — radio

7. Visit `/fm/radio`. → Station list renders.
8. Tune into a station. → Playback starts from the station's playlist;
   player bar shows station context; tune-in registers (station shows
   as playing).
9. Switch stations. → Old stream stops, new one starts cleanly.

## Steps — playlists

10. Visit `/fm/playlists` (logged in as operative). → Your playlists list;
    create a new playlist (name + description). → It appears.
11. Open the playlist; add tracks (from `/vault` add-to-playlist or an
    in-page add flow). → Tracks listed in order.
12. **Reorder**: drag a row to a new position (desktop) AND use the ↑/↓
    buttons (covers mobile path). → Order persists after a reload.
13. Remove a track. → Gone after reload.
14. **Share**: copy the share link and open it in a LOGGED-OUT second
    browser. → `/shared/<token>` renders the playlist read-only and
    plays.
15. Delete the playlist. → Confirmation; gone from the list; the share
    link now 404s.
