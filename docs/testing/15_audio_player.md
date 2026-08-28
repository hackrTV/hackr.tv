---
title: Audio Player Deep-Dive
area: Music & Player
minutes: 15
---
# Audio Player Deep-Dive

The permanent player is the highest-risk cross-cutting component. Beyond
the survival invariant (article 02), verify its controls end-to-end.

## Steps

1. Start a vault track. → Play/pause button flips to PAUSE; time
   advances; seek bar moves.
2. Pause, wait 3s, resume. → Resumes at the same position.
3. Drag the seek bar to ~80%. → Audio jumps; time display matches.
4. Adjust volume; then mute/unmute if present. → Takes effect
   immediately and persists across a Turbo navigation.
5. Queue panel: open it. → Shows current + upcoming tracks; click a
   queued track → jumps to it.
6. **Auto-advance**: seek near the end and let it finish. → Next track
   starts by itself (watchdog also recovers stalled advance — if
   playback ever freezes between tracks for >5s that's a FAIL).
7. **Crossfade/gapless via playlist settings**: play a playlist with a
   crossfade configured. → Transition honors it (no hard gap).
8. **Radio vs on-demand**: tune a radio station, then click a vault
   track. → Cleanly switches source; then back to radio.
9. **Now-playing publication**: while playing, hit
   `GET /api/overlay/now-playing` (curl or browser). → JSON shows your
   current track (the player POSTs state — this feeds OBS overlays).
10. **Cover art**: player bar + queue show covers; a track with no
    release cover shows the fallback, not a broken image.
11. Keyboard/media keys if wired (play/pause via media key). → Controls
    the player (best-effort; note behavior).
12. Kill the network briefly (devtools offline) mid-track, restore. →
    Player either continues from buffer or recovers on the next action;
    no wedged UI.
