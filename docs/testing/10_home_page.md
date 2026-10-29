---
title: Home Page + Live Banner
area: Music & Player
minutes: 13
---
# Home Page + Live Banner

## Steps

1. Visit `/` logged out. → Home page renders: hero/terminal styling, nav,
   no footer menu (dropped 2026-10-28; only the player bar is fixed at the
   bottom). No console errors.
2. Log in as the operative and revisit `/`. → Logged-in nav state (alias
   visible / grid entry present).
3. **Stream offline state**: with no live stream, the live panel /
   banner is absent or shows the offline state.
4. **Go live** (admin browser): `/root` → Streams → create/start a
   stream marked live (or use the admin API `POST /api/admin/streams/go_live`).
   → In the operative's browser the live banner appears WITHOUT a manual
   reload (stream-status broadcast).
5. With the stream live, check the home live panel: embedded player and
   the **docked Uplink chat** beside/below it, the same height as the
   player (the log scrolls inside the panel; it never grows the row).
6. Type a message into the docked chat. → It appears in the log; also
   visible in the second browser's `/uplink` (dual-surface check).
7. Click the popout control (`[^]`) on the docked chat. → `/uplink/popout`
   opens in a slim window and receives new messages live.
8. End the stream from admin. → Banner/panel clears live in the
   operative's browser.
9. Watch-time credit: while the stream is live and the tab visible, stay
   2+ minutes, then check the operative's profile stats
   (`/wire/<alias>`) later for increased watch time. (Coarse check —
   exact seconds not required.)
10. **Theater mode**: with the stream live, click `[=] THEATER`. → The
    embed and the docked chat fill the whole viewport, the LIVE NOW bar
    is gone, and the chat log is full height. `[x] EXIT` (top right) or
    Esc returns to the normal layout.
11. **Notice placement**: every top notice — the LIVE NOW banner on other
    pages, the NEXT STREAM countdown on `/` when a stream is scheduled
    but not live, flashes — renders fully visible directly below the
    header menu, never underneath it. Check logged out and logged in
    (the menu wraps to more rows) and at a narrow desktop width.
12. **Popped-out Uplink**: with the stream live, click `[^]` on the docked
    chat (normal layout, then again from theater mode). → The inline chat
    disappears and the player widens into its space (fills the viewport
    in theater). Close the popout window → the inline chat returns within
    a couple of seconds.
