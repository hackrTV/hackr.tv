---
title: PulseWire + WIRE Profiles
area: Social & Comms
minutes: 20
---
# PulseWire (/wire) + Profiles

## Steps — feed + posting

1. Visit `/wire` as the operative. → Feed renders; composer at top.
2. Post a pulse with plain text. → Appears at the top WITHOUT a reload;
   in the second browser's `/wire` it appears live (broadcast).
3. Post a pulse containing an `@mention` of the admin, a `[[codex]]`
   ref, and an external URL. → Mention links to the profile, codex ref
   links into `/codex`, external link is neutralized per wire rules
   (censored/inert — must NOT be a live outbound link).
4. **Echo** someone else's pulse from the second browser. → Echo count
   bumps live for both; echo attribution shown.
5. **Signal drop** (admin/moderation feature) on a pulse from the admin
   browser. → Pulse drops per rules.
6. Delete your own pulse (the "×" control). → Gone for both browsers.
   The delete control must NOT be visible on other people's pulses for
   a non-moderator (Phase 3 regression: it once leaked to everyone).
7. Single-pulse permalink: open a pulse's page. → Renders standalone
   with echoes.

## Steps — profiles

8. Visit `/wire/<operative-alias>`. → Profile header: role + clearance
   badges, member-since, online dot, bio, stat tiles (pulses, echoes,
   packets, achievements, watch time...), share link; pulse history
   below.
9. Vanity URL `/@<alias>`. → 301s to the profile; case-insensitive
   (`/@ALIAS` works).
10. **Bio edit** (own profile): edit inline, save. → Renders with
    @mention linking; an email address in the bio must be REJECTED by
    validation.
11. **Pin**: pin one of your pulses (max 3). → PINNED box at the top of
    the profile; the pinned pulse is not duplicated below in the feed.
12. Pin 3, try a 4th. → Rejected with a clear message.
13. **Reorder pins** (drag or controls). → Order persists on reload.
14. Unpin. → Removed from PINNED.
15. Anonymous view of the profile (logged-out browser). → Renders
    read-only; no edit/pin controls.
