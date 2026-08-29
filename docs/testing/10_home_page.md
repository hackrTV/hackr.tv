---
title: Home Page + Live Banner
area: Music & Player
minutes: 10
---
# Home Page + Live Banner

## Steps

1. Visit `/` logged out. → Home page renders: hero/terminal styling, nav,
   footer. No console errors.
2. Log in as the operative and revisit `/`. → Logged-in nav state (alias
   visible / grid entry present).
3. **Stream offline state**: with no live stream, the live panel /
   banner is absent or shows the offline state.
4. **Go live** (admin browser): `/root` → Streams → create/start a
   stream marked live (or use the admin API `POST /api/admin/streams/go_live`).
   → In the operative's browser the live banner appears WITHOUT a manual
   reload (stream-status broadcast).
5. With the stream live, check the home live panel: embedded player and
   the **docked Uplink chat** beside/below it.
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
