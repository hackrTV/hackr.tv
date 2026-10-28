---
title: PulseWire + WIRE Profiles
area: Social & Comms
minutes: 30
---
# PulseWire (/wire) + Profiles

The WIRE is a ledger (2026-10): one dense row per pulse — `HH:MM` gutter,
role-colored `@alias` + ADMIN/OP badge, body, `↻ n` echoes / `↩ n` replies
on the right — under a one-line `>` prompt, with threads expanding inline
under their root or, on wide screens, reading in the context pane beside
the feed. Keyboard: `?` shows the legend.

## Steps — feed + posting

1. Visit `/wire` as the operative. → Rows, newest first, split by
   `// TODAY · <date> //` / `// <date> //` separators in YOUR local day;
   times are local (hover a time for the full date). `● LIVE` in the bar.
2. Type in the `>` prompt and press Enter. → Appears at the top WITHOUT a
   reload under TODAY; the counter ("255 / 256"…) reads remaining; the
   prompt clears. Shift+Enter inserts a newline; `[>] TX` sends too. In
   the second browser's `/wire` it appears live (broadcast).
3. Post a pulse containing an `@mention` of the admin, a `[[codex]]`
   ref, and an external URL. → Mention links to the profile, codex ref
   links into `/codex`, external link is neutralized per wire rules
   (censored/inert — must NOT be a live outbound link). `:slug:`
   autocomplete still works in the prompt.
4. **Echo** someone else's pulse (`↻`) from the second browser. → `↻ 1`
   bumps live for both; only the echoer's `↻` turns blue.
5. **Thread**: click `↩` on a pulse. → Its thread unfolds under the row
   (no page change): replies oldest first, 14px, a `[>] re @alias · …`
   quote line on replies to a reply, and a `> Splice into @alias's
   thread...` prompt at the bottom. Post a splice. → Lands in the open
   thread, the root's `↩ n` bumps (also live in the other browser if its
   thread is open). Click a reply's `↩`. → The prompt re-aims at that
   reply (placeholder "Reply to @alias..."). Click the root's `↩` again.
   → Folds (and unfolds without refetching).
6. **Pulse drop** (admin) on a pulse with an open thread. → The row
   becomes a dim `[ PULSE DROPPED BY GOVCORP ] moderated HH:MM` line in
   both browsers; the open thread under it empties.
7. Delete your own pulse (the red `×`). → Gone for both browsers. The
   `×` must NOT be visible on other people's pulses (Phase 3 regression:
   it once leaked to everyone).
8. **Keys** (desktop): `j`/`k` move a cursor row (purple outline), `e`
   echoes it, `o` unfolds its thread, `r` opens it and focuses the reply
   prompt, `/` focuses the top prompt, `x` on your own row arms it (red
   ×) and a second `x` within 1.5s deletes, `?` toggles the legend,
   `Esc` closes it and clears the cursor. Keys do nothing while typing.
9. **Context pane** (desktop ≥1280px wide, first visit): `[>] CONTEXT`
   in the bar reads pressed and a 380px pane sits beside the feed
   reading `// SELECT A PULSE //`. Press `j` twice. → The cursor row
   gets a purple left bar and the pane shows `THREAD #id · n PULSES`,
   the root in full (local date + time), its replies and a splice
   prompt; the row's inline thread does NOT unfold. Move with `j`/`k`.
   → The pane follows the cursor (a short beat later).
10. In the pane, post a splice. → It lands in the pane; the row's `↩ n`
    bumps. Press `r` on the row. → The pane's prompt takes focus. Click
    a reply's `↩` in the pane. → The prompt re-aims (placeholder "Reply
    to @alias..."). `[>] PAGE` opens the thread page.
11. Click an `@alias` in a row (plain click). → The pane shows the
    OPERATIVE record (alias, role, CL, member since, activity, bio, six
    stats) with `[>] PROFILE`; the URL stays `/wire`. Ctrl/middle-click
    an alias. → The profile opens as usual. `a` on the cursor row does
    the same as the plain click.
12. Press `c` (or the pane's `[x]`, or `[>] CONTEXT`). → The pane closes;
    `↩` now unfolds threads inline as in step 5. Reload. → Still closed
    (remembered per browser); `c` again reopens it and, with a cursor
    row, shows that thread at once — an inline thread you had open for
    that row folds (one copy of a thread on the page).
13. Narrow the window under 1100px. → The pane and `[>] CONTEXT` go away
    and threads stay inline; widen it again. → They return (the pane
    empty until a row is selected).
14. Single-pulse permalink: open `/wire/pulse/<id>`. → `< WIRE  Thread
    n pulses`, the root row with its thread already open.
15. Phone width (<768px). → Each row is a meta line (time · alias ·
    badge · counts) over the body; your `×` is visible without hover;
    the thread indents under the row; the `[?] KEYS` button is hidden.

## Steps — profiles

16. Visit `/wire/<operative-alias>`. → Status line: `< WIRE  @alias
    ROLE  CLn  MEMBER SINCE <date>  ● activity  [⧉ SHARE]`, the bio
    line, a 6-cell stat strip (WIRE PULSES, ECHOES, PACKETS,
    ACHIEVEMENTS, BREACHES, WATCH TIME); `// BROADCASTS //` rows below
    — own pulses + pulses they echoed (an `ECHO` badge under the alias;
    replies carry the `[>] re` quote line).
17. Vanity URL `/@<alias>`. → 301s to the profile; case-insensitive
    (`/@ALIAS` works).
18. **Bio edit** (own profile): `✎ EDIT` inline, save. → Renders with
    @mention linking; an email address in the bio must be REJECTED by
    validation.
19. **Pin** (`◆ PIN`): pin one of your pulses (max 3). → `// PINNED 1/3
    //` rows at the top with a gold left bar + `PIN` badge; the pinned
    pulse is not duplicated below.
20. Pin 3, try a 4th. → Rejected with a clear message.
21. **Reorder pins** (`↑`/`↓`). → Order persists on reload.
22. Unpin (`◆ UNPIN`). → Removed from PINNED, back in BROADCASTS once.
23. View someone else's profile. → No `✎ EDIT`, no pin controls, no `×`.
