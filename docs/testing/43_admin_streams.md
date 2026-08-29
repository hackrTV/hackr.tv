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
   duration; `[VOD]` link appears on `/schedule`; the VOD shows in the
   artist's `/vidz`.
5. Delete the test stream. → Gone everywhere (vidz list, schedule).
   Deleting a stream that accumulated watch sessions must succeed
   (sessions nullify, no FK error).
