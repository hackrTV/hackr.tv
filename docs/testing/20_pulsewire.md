---
title: PulseWire + WIRE Profiles
area: Social & Comms
minutes: 24
---
# PulseWire (/wire) + Profiles

The WIRE is a ledger (2026-10): one dense row per pulse — `HH:MM` gutter,
role-colored `@alias` + ADMIN/OP badge, body, `↻ n` echoes / `↩ n` replies
on the right — under a one-line `>` prompt, with threads expanding inline
under their root. Keyboard: `?` shows the legend.

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
9. Single-pulse permalink: open `/wire/pulse/<id>`. → `< WIRE  Thread
   n pulses`, the root row with its thread already open.
10. Phone width (<768px). → Each row is a meta line (time · alias ·
    badge · counts) over the body; your `×` is visible without hover;
    the thread indents under the row; the `[?] KEYS` button is hidden.

## Steps — profiles

11. Visit `/wire/<operative-alias>`. → Status line: `< WIRE  @alias
    ROLE  CLn  MEMBER SINCE <date>  ● activity  [⧉ SHARE]`, the bio
    line, a 6-cell stat strip (WIRE PULSES, ECHOES, PACKETS,
    ACHIEVEMENTS, BREACHES, WATCH TIME); `// BROADCASTS //` rows below
    — own pulses + pulses they echoed (an `ECHO` badge under the alias;
    replies carry the `[>] re` quote line).
12. Vanity URL `/@<alias>`. → 301s to the profile; case-insensitive
    (`/@ALIAS` works).
13. **Bio edit** (own profile): `✎ EDIT` inline, save. → Renders with
    @mention linking; an email address in the bio must be REJECTED by
    validation.
14. **Pin** (`◆ PIN`): pin one of your pulses (max 3). → `// PINNED 1/3
    //` rows at the top with a gold left bar + `PIN` badge; the pinned
    pulse is not duplicated below.
15. Pin 3, try a 4th. → Rejected with a clear message.
16. **Reorder pins** (`↑`/`↓`). → Order persists on reload.
17. Unpin (`◆ UNPIN`). → Removed from PINNED, back in BROADCASTS once.
18. View someone else's profile. → No `✎ EDIT`, no pin controls, no `×`.
