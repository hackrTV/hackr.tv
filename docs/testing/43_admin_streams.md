---
title: Admin — Hackr Streams
area: Admin
minutes: 10
---
# Admin — Hackr Streams

## Steps

1. `/root` → Streams. → Index with display states (scheduled / live /
   past).
2. Create a SCHEDULED stream (future time, artist, title). → Appears on
   public `/schedule` under upcoming with correct local time.
3. Edit it to live (or use go-live). → Home page live banner appears
   (article 10 verified the broadcast); `/schedule` reflects it.
4. End it; attach a `vod_url`. → Moves to past broadcasts with
   duration; `[VOD]` link appears on `/schedule` for a TCP or XERAEN
   stream (any other artist's recording has no page, so no link); the
   VOD shows on `/thecyberpulse/vidz` (TCP and XERAEN streams only — the
   archive);
   if it is the newest past broadcast, the home console's LAST TX title
   now opens that VOD page (`· VOD` marker) instead of `/schedule`.
5. Delete the test stream. → Gone everywhere (vidz list, schedule).
   Deleting a stream that accumulated watch sessions must succeed
   (sessions nullify, no FK error).
