---
title: Uplink Comms
area: Social & Comms
minutes: 25
---
# Uplink (/uplink)

## Steps — the NODE shell

1. Visit `/uplink` as the operative. → Discord-shaped shell: a thin rail
   with the hackr.tv node, a channel sidebar (UPLINK / hackr.tv NODE
   header, channels grouped under category headings such as BROADCAST
   and COMMS, your @alias + role in the bottom panel), the channel pane
   (channel name + description as the topic, slow-mode chip when set,
   presence, `[^]` popout, `[o] OPERATIVES` toggle), and the OPERATIVES
   pane on the right. The shell fills the viewport between the site
   header and the bottom; no page scroll.
2. Start a track from `/vault` in another tab, come back. → The shell
   shortens so the composer stays above the player bar; closing the
   player gives the room back.
3. `[o] OPERATIVES` collapses/expands the right pane and is remembered
   on reload. In `/root/uplink` edit a channel's category/position. →
   Sidebar grouping/order follows.
4. Narrow the window under 768px. → Rail hidden; `[#]` in the channel
   header opens the channel list as a drawer over the pane, `[o]` the
   operatives drawer; backdrop click or Escape closes; the pane behind
   is inert while open.

## Steps — basic chat

5. Send a packet (Enter sends; Shift+Enter inserts a newline; `/` from
   anywhere focuses the composer; `:)` opens the emote picker with
   every emote). → Appears in the log instantly; second browser on
   `/uplink` sees it live; presence count reflects both viewers; a
   multi-line packet keeps its line breaks.
6. Send three packets in a row within a few minutes. → The second and
   third collapse under the first (no repeated author line); hovering
   a collapsed packet shows its time. A packet from someone else, or
   after a five-minute gap, starts a new group.
7. Scroll up in a busy channel while the other browser sends. → A
   `[v] N NEW PACKETS` pill floats over the log instead of yanking you
   down; click it (or send your own packet) to jump back to the bottom.
8. Switch channels via the sidebar (`?channel=` URLs). → Log swaps to
   that channel's history; sends go to the right channel; the active
   row is highlighted and the header shows the channel name.
9. **Scrollback**: in a channel with more than 20 packets, scroll to
   the top of the log. → The strip above the first packet reads
   `// RETRIEVING ARCHIVE //` and up to 40 older packets slide in above
   it without the packet you were reading moving; author groups
   continue across the seam; the `[v] NEW PACKETS` pill never appears
   for history. Keep going → at the oldest packet the strip reads
   `// BEGINNING OF CHANNEL //` and stops. The dock and popout have no
   scrollback.
10. **Slow mode**: send two packets rapidly. → Second is throttled with
    a cooldown message/disabled TX until the window passes; focus
    returns to the composer when the cooldown ends.
11. Emoji/plain text render; an @mention of the other session renders
    highlighted for them (self-mention styling). **Mention toast**: with
    the other session reading a different channel (or any other page),
    mention them. → A `@MENTION` toast slides in bottom-right naming the
    sender, the channel and an excerpt; in the shell that channel's
    sidebar row gets a `@` badge. Clicking the toast opens the channel
    (badge gone, packet highlighted). Mention them while they read the
    same channel scrolled up. → No toast; the jump pill reads
    `[v] @ MENTION · N NEW PACKETS`.

12. **Replies**: hover another packet → `↩` appears beside the drop
    control; click it. → The composer shows `[>] REPLYING TO @alias [x]`
    and takes focus; Escape (or `[x]`) clears it. Arm it again and send.
    → The reply renders with a `[>] @alias excerpt` quote line above
    your text, for both browsers, and never collapses under your
    previous packet. Click the quote → the original packet scrolls into
    view and flashes. Drop the original as admin → the quote reads
    `[PACKET DROPPED]` live; restore → the excerpt returns. The dock and
    popout show quote lines but have no reply control.

## Steps — operatives pane

13. With the second browser on the same channel. → It appears in the
    OPERATIVES pane under its role heading as a callsign (`SIG-XXXXXX`),
    never its alias; your own row shows your real @alias. Close the
    second browser → its row leaves within a few seconds (debounced
    broadcast; needs the job worker running).
14. A livestream channel (`#live`) while a stream is live. → The stream
    embeds above the log inside the shell; `[-] HIDE VIDEO` collapses it
    (and stops its audio), remembered on reload. The home page embed and
    theater mode are unchanged.

## Steps — moderation (operative + admin)

15. As admin (moderator role) in `/uplink`: hover another user's packet
    and drop it. → Packet shows dropped state for everyone live.
16. Restore it. → Restored live.
17. The drop control is NOT visible to the non-moderator operative on
    others' packets.
18. **Squelch** the operative from `/root` → Uplink (punishments). → In
    the operative's `/uplink`, the composer is replaced by the squelch
    notice; sending is impossible. Lift the squelch → composer returns
    (after reload).
19. **Blackout** the operative. → Uplink is fully blocked with the
    blackout notice. Lift it afterwards.

## Steps — popout + recovery

20. Open `/uplink/popout` (`[^]`). → Slim chrome-less window with the
    classic single-line panel; live receive + send both work; heartbeat
    keeps it registered while open. The home-page dock is likewise the
    classic panel.
21. Kill the connection (devtools offline ~10s, restore). → The log
    recovers missed messages (reconnect frame reload) rather than
    silently gapping.

## Steps — external bridge spot-check (if relay/synthia are running)

22. Send from hackr.tv `/uplink`, including a two-line packet. →
    Appears in relay's terminal view (line breaks are plain `\n`).
23. Send via synthia (or
    `POST /api/admin/uplink/send_packet` with the Bearer token). → The
    packet appears live in `/uplink` attributed to the service account;
    the bridge account never shows in the OPERATIVES pane.
