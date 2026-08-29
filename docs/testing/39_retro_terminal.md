---
title: Retro Terminal (/terminal)
area: The Grid
minutes: 15
---
# Retro Terminal (/terminal)

The standalone retro terminal experience (also the easter-egg iframe).
Server-driven UI with its own live subscriptions.

## Steps

1. Visit `/terminal` directly. → Boot/intro types out (typing
   animation); skip works via keypress; menu renders (numbered
   options: PulseWire, etc.).
2. Navigate the menu (`2` for PulseWire, `/wire` shortcut). → Wire view
   renders in terminal styling.
3. **Live wire**: with the terminal open on the wire view, post a pulse
   from the browser `/wire` (other session). → The pulse appears in
   the TERMINAL live (raw pubsub subscription — this is the canary for
   the pulse_wire JSON broadcast).
4. Uplink view in the terminal: open it; send a packet from browser
   `/uplink`. → Appears live in the terminal.
5. Grid handler: enter the grid area in the terminal (login flow if
   prompted). → Room output renders; movement between rooms shows
   live room events from the other account moving nearby.
6. Easter-egg overlay parity (article 02 opened it): interactions
   inside the iframe behave identically to the direct visit.
7. Audit trail: terminal sessions log (admin can spot-check
   logs/audit_log if surfaced) — no errors in server log during the
   session.
