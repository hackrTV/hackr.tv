---
title: hackr.fm — Radio, Releases, Playlists
area: Music & Player
minutes: 20
---
# hackr.fm (/fm)

## Steps — landing + releases

1. Visit `/fm`. → Landing renders: latest releases strip, coming-soon
   strip (cover variants load — a broken image here historically means
   the libvips variant pipeline, see gotchas), radio + playlists entries.
2. Visit `/fm/releases`. → Release grid with covers; coming-soon items
   marked and NOT playable.
3. Open a release. → Track list with numbers/durations; disc length;
   clicking a track plays it and queues the release order.

## Steps — radio

4. Visit `/fm/radio`. → Station list renders.
5. Tune into a station. → Playback starts from the station's playlist;
   player bar shows station context; tune-in registers (station shows
   as playing).
6. Switch stations. → Old stream stops, new one starts cleanly.

## Steps — playlists

7. Visit `/fm/playlists` (logged in as operative). → Your playlists list;
   create a new playlist (name + description). → It appears.
8. Open the playlist; add tracks (from `/vault` add-to-playlist or an
   in-page add flow). → Tracks listed in order.
9. **Reorder**: drag a row to a new position (desktop) AND use the ↑/↓
   buttons (covers mobile path). → Order persists after a reload.
10. Remove a track. → Gone after reload.
11. **Share**: copy the share link and open it in a LOGGED-OUT second
    browser. → `/shared/<token>` renders the playlist read-only and
    plays.
12. Delete the playlist. → Confirmation; gone from the list; the share
    link now 404s.
