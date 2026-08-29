---
title: Uplink Comms
area: Social & Comms
minutes: 20
---
# Uplink (/uplink)

## Steps — basic chat

1. Visit `/uplink` as the operative. → Channel tabs render (ambient at
   minimum); packet log shows recent history; composer with TX button.
2. Send a packet. → Appears in the log instantly; second browser on
   `/uplink` sees it live; presence count reflects both viewers.
3. Switch channels via tabs (`?channel=` URLs). → Log swaps to that
   channel's history; sends go to the right channel.
4. **Slow mode**: send two packets rapidly. → Second is throttled with
   a cooldown message/disabled TX until the window passes.
5. Emoji/plain text render; an @mention of the other session renders
   highlighted for them (self-mention styling).

## Steps — moderation (operative + admin)

6. As admin (moderator role) in `/uplink`: drop another user's packet.
   → Packet shows dropped state for everyone live.
7. Restore it. → Restored live.
8. The drop control is NOT visible to the non-moderator operative on
   others' packets.
9. **Squelch** the operative from `/root` → Uplink (punishments). → In
   the operative's `/uplink`, the composer is replaced by the squelch
   notice; sending is impossible. Lift the squelch → composer returns
   (after reload).
10. **Blackout** the operative. → Uplink is fully blocked with the
    blackout notice. Lift it afterwards.

## Steps — popout + recovery

11. Open `/uplink/popout`. → Slim chrome-less window; live receive +
    send both work; heartbeat keeps it registered while open.
12. Kill the connection (devtools offline ~10s, restore). → The log
    recovers missed messages (reconnect frame reload) rather than
    silently gapping.

## Steps — external bridge spot-check (if relay/synthia are running)

13. Send from hackr.tv `/uplink`. → Appears in relay's terminal view.
14. Send via synthia (or
    `POST /api/admin/uplink/send_packet` with the Bearer token). → The
    packet appears live in `/uplink` attributed to the service account.
