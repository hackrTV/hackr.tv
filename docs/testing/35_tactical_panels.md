---
title: Tactical Panels — Vendor, NPC, Transit, Rest Pod
area: The Grid
minutes: 30
---
# Tactical Slide-In Panels

Move to the rooms noted in article 01 (vendor / quest giver / transit /
rest pod). Each context handle appears in the room-flags strip only when
the room has that feature.

## Steps — vendor

1. In the vendor room, click the vendor handle. → Panel slides in:
   vendor name, listings with prices, your CRED.
2. BUY an affordable item (confirm dialog). → Output confirms; CRED
   drops; item in INVENTORY tab.
3. Attempt a purchase you can't afford. → Clear rejection, no debit.
4. SELL the item back (sell price < buy price). → CRED back; item gone.

## Steps — NPC dialogue

5. In an NPC room, open the NPC panel. → Avatar (if set), name +
   faction, greeting, topic buttons.
6. Click a topic WITH children (`›` marker). → Response renders in the
   panel; breadcrumb shows the path; child topic buttons + ← BACK +
   RESET appear.
7. Click a LEAF topic. → The response text appears in the panel (the
   last-exchange mirror) AND the topic buttons remain visible.
8. BACK returns a level; RESET returns to the greeting.
9. Reserved keywords: asking about `work`/`missions` routes to mission
   handling, not the dialogue tree.

## Steps — NPC missions (quest giver)

10. At the quest giver with an available mission: the panel shows
    DIALOGUE/MISSIONS tabs. MISSIONS → AVAILABLE lists the mission with
    description, objectives, rewards; gate warnings ([CLEARANCE N] etc.)
    when unmet.
11. ACCEPT (confirm dialog). → Mission moves to ACTIVE with 0-progress
    objectives; MISSIONS status tab + `/missions` page agree.
12. For a deliver objective: with the item in inventory, the DELIVER
    button enables and shows held/needed; click. → Progress ticks.
13. Complete all objectives → READY badge; TURN IN. → Rewards granted
    (XP/CRED/rep/items per mission), completion toast fires, `/missions`
    live-refreshes (see article 37 step 6).
14. Accept another mission and ABANDON it (confirm). → Removed from
    active; repeatable missions return to available.

## Steps — transit

15. In a transit-stop room, open the transit panel. → Departure board:
    local routes (+fares), slipstream if present, private options where
    unlocked.
16. Board a route you can afford (`board`/panel button). → Journey
    starts; arrival at the destination room updates map/room; fare
    debited (CRED tab).
17. Attempt with insufficient CRED. → Rejected cleanly.

## Steps — rest pod

18. In a rest-pod room with damaged vitals (take damage first, or use a
    consumable to lower vitals): open the pod panel → REST. → Vitals
    restore over/after the rest per rules; bar vitals + STATS tab
    update.
