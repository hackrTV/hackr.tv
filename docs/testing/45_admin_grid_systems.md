---
title: Admin — Grid Systems (Items, Shops, Missions, Breach, Transit, Factions)
area: Admin
minutes: 30
---
# Admin — Grid Systems CRUD

## Steps — item definitions + shops

1. Grid → Item Defs. → 85+ definitions, 12 types; open one → stats,
   rarity, salvage yields.
2. Create a TEST item definition (cheap material). → Grant one to the
   operative (Hackrs → item grant, or `item_grant` dev command). →
   Appears in inventory; `salvage` behaves per its yields.
3. Grid → Shops (listings). → Listings per vendor; add a TEST listing
   for the test item to your TEST vendor (article 44). → Buyable
   in-game; remove it after.

## Steps — achievements

4. Grid → Achievements. → 79+ achievements with categories, triggers,
   hidden flags. Open one → reward config.
5. Manually award one to the operative (admin award action). → Toast
   fires (article 02), `/achievements` shows it earned.

## Steps — missions + arcs

6. Grid → Missions. → Missions with givers, objectives, rewards,
   gates. Create a TEST mission on your TEST NPC: 1 simple objective
   (e.g. deliver 1 test item), small XP reward, no gates. → In-game
   the giver offers it; run the full accept → progress → turn-in loop.
7. Mission Arcs. → Arc list renders; arc membership shown on missions.
8. Delete the TEST mission after turn-in. → Gone from giver +
   `/missions` available.

## Steps — breach config

9. Grid → Breach Templates. → 42 templates with tiers + protocol
   configs. Open one → protocols, thresholds, rewards.
10. Breach Encounters. → Encounter placements (room ↔ template); the
    one you fought in article 36 is listed.

## Steps — transit config

11. Grid → Transit Types / Transit Routes / Slipstream / Journeys. →
    Types (13 vehicle types), routes with stops + fares, slipstream
    legs, journey log of your article-35 ride.
12. Create a TEST local route between two stops (inline stop
    management), verify it appears on the in-game departure board,
    then delete it.

## Steps — factions + schematics

13. Grid → Factions. → 7 factions with rep tier config; the operative's
    standing visible where surfaced.
14. Grid → Schematics. → 29 schematics with material requirements
    matching the in-game `schematics` output.
