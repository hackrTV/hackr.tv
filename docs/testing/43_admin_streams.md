---
title: Admin — Hackr Streams
area: Admin
minutes: 10
---
# Admin — Hackr Streams

## Steps

1. `/root` → Streams. → The `STREAMS` console ledger (article 42's
   idiom): LIVE NOW (or NO ACTIVE LIVESTREAM), `[NN]` rows newest first
   — artist over title / started / ended / URL, the scheduled time, the
   state (LIVE lit, SCHEDULED cyan, STARTING SOON amber, CANCELLED red,
   ENDED / EXPIRED dim) and the actions the state allows: `[GO LIVE]`
   (has a live URL, not ended or cancelled), `[END]` (live), `[CANCEL]`
   (scheduled), `[EDIT]`. An `ON AIR` badge sits in the bar while a
   stream is live.
2. `[+] NEW STREAM`: a SCHEDULED stream (future time, artist, title,
   live URL). → Its record opens with `[OK]`; it appears on public
   `/schedule` under upcoming with the correct local time.
3. `[GO LIVE]` on its ledger row → confirm. → Home page live banner
   appears (article 10 verified the broadcast); `/schedule` reflects it.
4. `[END]` → confirm; open the record, attach a VOD URL, `[SAVE
   STREAM]`. → Moves to past broadcasts with duration; `[VOD]` link
   appears on `/schedule` for a TCP or XERAEN stream (any other artist's
   recording has no page, so no link); the VOD shows on
   `/thecyberpulse/vidz` (TCP and XERAEN streams only — the archive); if
   it is the newest past broadcast, the home console's LAST TX title now
   opens that VOD page (`· VOD` marker) instead of `/schedule`.
5. A cancelled stream's record shows a CANCELLED row. Change only the
   title and save. → Still CANCELLED. Set a new SCHEDULED and save. →
   The cancellation clears.
6. `[DELETE STREAM]` on the test stream's record → confirm. → Gone
   everywhere (vidz list, schedule). Deleting a stream that accumulated
   watch sessions must succeed (sessions nullify, no FK error).
