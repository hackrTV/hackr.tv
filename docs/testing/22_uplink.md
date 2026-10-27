---
title: Uplink Comms
area: Social & Comms
minutes: 47
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
5. **Sidebar extras**: click a category heading → its rows fold away
   (`[+]`) except the channel on screen and unread ones; a packet
   landing in a folded channel brings its row back; remembered on
   reload. Tab into the channel list → one stop (the active row); ↑/↓
   walk headings + rows, Home/End jump, ←/→ fold/unfold a heading, ←
   on a row climbs to its heading. Ctrl+K (⌘K, or `[>] JUMP TO
   CHANNEL` under the NODE header) → quick switcher: type to filter
   (name first, then category), ↑/↓, Enter visits, Esc closes back to
   where you were. Each row shows its connected count (faint number
   before the badge, hidden at 0): the second browser joining or
   leaving a channel moves it within a few seconds. With packets
   unread elsewhere the tab title reads `(N) Uplink — hackr.tv`,
   `(@N)` when one mentions you, plain again once caught up.

## Steps — basic chat

6. Send a packet (Enter sends; Shift+Enter inserts a newline; `/` from
   anywhere focuses the composer; `:)` opens the emote picker with
   every emote). → Appears in the log instantly; second browser on
   `/uplink` sees it live; presence count reflects both viewers; a
   multi-line packet keeps its line breaks.
7. Send three packets in a row within a few minutes. → The second and
   third collapse under the first (no repeated author line); hovering
   a collapsed packet shows its time. A packet from someone else, or
   after a five-minute gap, starts a new group.
8. Scroll up in a busy channel while the other browser sends. → A
   `[v] N NEW PACKETS` pill floats over the log instead of yanking you
   down; click it (or send your own packet) to jump back to the bottom.
9. Switch channels via the sidebar (`?channel=` URLs). → Log swaps to
   that channel's history; sends go to the right channel; the active
   row is highlighted and the header shows the channel name.
10. **Unread badges**: with the second browser on `#trace`, send two
    packets there from the first browser while it reads `#ambient`. →
    Its `#trace` sidebar row brightens with a `2` badge live (no
    reload); the active channel never badges. Click `#trace` → the
    badge is gone and a `// NEW PACKETS //` line sits right above the
    first packet you had not seen (packets after it start a fresh
    author group). With more unseen than the log normally holds (up to
    100) the log opens scrolled to the line with a few earlier packets
    above it for context; beyond that it opens at the newest and the
    line appears where the unseen start as you scroll back.
    Back to `#ambient` → still no badge (the visit marked it read). Stay on `#trace` at the bottom while the other
    browser sends there, wait two seconds, switch away. → No badge for
    what you watched. Scroll up in `#trace`, let a packet land, switch
    away. → It counts (you never saw it). Over 99 unread reads `99+`.
11. **Scrollback**: in a channel with more than 20 packets, scroll to
    the top of the log. → The strip above the first packet reads
    `// RETRIEVING ARCHIVE //` and up to 40 older packets slide in above
    it without the packet you were reading moving; author groups
    continue across the seam; the `[v] NEW PACKETS` pill never appears
    for history. Keep going → at the oldest packet the strip reads
    `// BEGINNING OF CHANNEL //` and stops. The dock and popout have no
    scrollback.
12. **Slow mode**: send two packets rapidly. → Second is throttled with
    a cooldown message/disabled TX until the window passes; focus
    returns to the composer when the cooldown ends.
13. Emoji/plain text render; an @mention of the other session renders
    highlighted for them (self-mention styling). **Mention toast**: with
    the other session reading a different channel (or any other page),
    mention them. → A `@MENTION` toast slides in bottom-right naming the
    sender, the channel and an excerpt; in the shell that channel's
    sidebar badge turns accent (the count itself comes from the packet's
    bump). Clicking the toast opens the channel
    (badge gone, packet highlighted). Mention them while they read the
    same channel scrolled up. → No toast; the jump pill reads
    `[v] @ MENTION · N NEW PACKETS`.

14. **Replies**: hover another packet → `↩` appears among the hover
    controls; click it. → The composer shows `[>] REPLYING TO @alias [x]`
    and takes focus; Escape (or `[x]`) clears it. Arm it again and send.
    → The reply renders with a `[>] @alias excerpt` quote line above
    your text, for both browsers, and never collapses under your
    previous packet. Click the quote → the original packet scrolls into
    view and flashes. Drop the original as admin → the quote reads
    `[PACKET DROPPED]` live; restore → the excerpt returns. The dock and
    popout show quote lines but have no reply control.
15. **Operative record**: click a packet author's `@alias`. → A card pops
    up beside it — alias in its role color, role badge, `CL<n>`, member
    since, last active, bio, PACKETS / WIRE PULSES / ECHOES /
    ACHIEVEMENTS tiles, `[WIRE PROFILE]` — and the page does not
    navigate. Escape, `[x]`, clicking elsewhere or clicking the same
    author again closes it; ctrl/middle-click the author → the WIRE
    profile opens as before. Roster callsigns open nothing. In the dock
    and popout the author link still goes straight to the WIRE profile.
16. **Reactions**: hover a packet → `:)` leads the hover controls; click
    it. → A REACT picker parks under it listing every emote (needs at
    least one at `/root/emotes`); pick one. → The picker closes and a
    `:emote: 1` chip appears under the packet in both browsers, outlined
    accent in yours only. In the second browser click the chip → `2`,
    outlined there too; click yours → `1` and your outline leaves. Open
    the picker on a packet you reacted to → that emote is marked, and
    picking it removes the reaction. Drop the packet as admin → the
    chips vanish; restore → they return. The dock and popout show the
    chips (clickable, outlined when yours) but no `:)`.
17. **Typing**: in the second browser, start typing in the composer
    without sending. → Within a second your browser reads
    `@alias is transmitting...` in the strip between log and composer;
    the typer's own browser shows nothing there. Type in both → each
    sees the other's alias only. Send → the line clears at
    once; stop typing without sending → it clears within ~5s; clear the
    field or click away from it → it clears at once. The dock and popout
    show no typing line and never report typing.

18. **Search**: hit `[/] SEARCH` in the header. → The operatives pane
    becomes a SEARCH face (wider) with the field focused; type a word
    from an old packet and press Enter. → Hits list newest first with
    the matches marked, sender + age per row. Click a hit that is in
    the log → it scrolls into view and blinks; the hits stay. Click one
    beyond the loaded history → the page reloads with the log opened on
    that packet (blinking, 20 packets either side), the search still in
    the pane, and the pill reads `[v] JUMP TO PRESENT`; scroll to the
    end → newer pages slide in until the present (packets sent
    meanwhile appear then, in order), or hit the pill → the newest
    packets, search kept. `[x]`, Escape in the field or `[o]` bring
    the roster back. `%` and `_` match themselves. The dock and popout
    have no search.

## Steps — operatives pane

19. With the second browser on the same channel. → It appears in the
    OPERATIVES pane under its role heading as a callsign (`SIG-XXXXXX`),
    never its alias; your own row shows your real @alias. Close the
    second browser → its row leaves within a few seconds (debounced
    broadcast; needs the job worker running).
20. A livestream channel (`#live`) while a stream is live. → The stream
    embeds above the log inside the shell; `[-] HIDE VIDEO` collapses it
    (and stops its audio), remembered on reload. The home page embed and
    theater mode are unchanged.

## Steps — moderation (operative + admin)

21. As admin (moderator role) in `/uplink`: hover another user's packet
    → no `×` anywhere on the shell; click its `...` → DROP PACKET. →
    Packet shows dropped state for everyone live. Hover it again → the
    row stays faded but its `...` reads as clearly as on a live packet
    → RESTORE PACKET. → Restored live. (The dock and popout keep their
    `×` / `↺`.)
22. As the operative, hover your own packet → its `...` opens a YOUR
    PACKET menu holding DROP PACKET alone (no reason, no punishments);
    drop it. → `[PACKET DROPPED]` for everyone; hovering it now shows no
    `...` (only operators restore). Hover someone else's packet → no
    `...`, no `×`.
23. A bridged packet (relay/synthia, or one seeded with `source: "TTV"`):
    as admin its `...` opens MODERATE `TTV <user>` with DROP PACKET only
    — no squelch/blackout, and the bridge account's alias appears
    nowhere. The operative gets no `...` on it.
24. **Operator menu**: as admin, hover the operative's packet → a `...`
    appears among the hover controls; click it. → A small MODERATE menu
    parks under it naming `@alias` in its role color: a REASON field,
    DROP PACKET, SQUELCH 10M / 1H / 24H, BLACKOUT, `[x]`. Enter in the
    reason field does nothing; Escape or clicking elsewhere closes it.
    Type a reason and click SQUELCH 10M. → The menu closes, a MODERATION
    toast reads `@alias squelched for 10m.`, and `/root/uplink`'s
    moderation log has the row with the reason. Reopen the menu. → It
    shows `SQUELCHED · 10M LEFT`, no squelch items, and LIFT PUNISHMENT.
    In the OPERATIVES pane hover the operative's callsign row. → The same
    `...` is there; its menu names only `SIG-XXXXXX` (never the alias) and
    has no DROP PACKET. Your own row, other admins' rows and packets by
    admins show no `...` (your own packets show the YOUR PACKET one); an
    operator (not admin) sees it on operatives, bridged packets and their
    own packets only. BLACKOUT, then LIFT PUNISHMENTS from either menu →
    toasts confirm, the status lines follow.
25. **Pins**: as admin, hover a packet → a `◆` sits between `↩` and the
    `...`; click it. → The row gains an amber left bar + a `PIN` badge
    for everyone live, and the header's `[◆] PINNED` count ticks to 1 (the
    operative sees both, but no `◆` on hover). Click `[◆] PINNED`. → A
    PINNED panel parks under it listing the packet (sender, age, excerpt)
    with UNPIN beside it; `[x]`, Escape or clicking elsewhere closes it.
    Open it as the operative → same list, no UNPIN; click the row → the
    panel closes and the packet flashes in the log. Drop the pinned
    packet → the count reads 0 (the pin parks); restore it → 1. In the
    admin's panel, UNPIN → the row vanishes, the panel stays open reading
    `No pinned packets…`, the count reads 0, the bar is gone everywhere.
    The popout/dock show no `◆`, no count, no panel.
26. **Squelch** the operative from `/root` → Uplink (punishments) or the
    operator menu. → In the operative's `/uplink`, the composer is
    replaced by the squelch notice on their next load; sending is
    impossible. Lift the squelch → composer returns (after reload).
27. **Blackout** the operative. → Uplink is fully blocked with the
    blackout notice. Lift it afterwards.

## Steps — popout + recovery

28. Open `/uplink/popout` (`[^]`). → Slim chrome-less window with the
    classic single-line panel; live receive + send both work; heartbeat
    keeps it registered while open. The home-page dock is likewise the
    classic panel. Neither has an operator menu: no `...` on packets.
29. Kill the connection (devtools offline ~10s, restore). → The log
    recovers missed messages (reconnect frame reload) rather than
    silently gapping, and the OPERATIVES pane refetches its roster.

## Steps — external bridge spot-check (if relay/synthia are running)

30. Send from hackr.tv `/uplink`, including a two-line packet. →
    Appears in relay's terminal view (line breaks are plain `\n`).
31. Send via synthia (or
    `POST /api/admin/uplink/send_packet` with the Bearer token). → The
    packet appears live in `/uplink` attributed to the service account;
    the bridge account never shows in the OPERATIVES pane.
