---
title: Economy, Crafting, Dens
area: The Grid
minutes: 30
---
# Economy, Crafting, Dens (terminal systems)

Run in `/grid` or `/grid/1337` — these are command-driven systems.

## Steps — CRED + caches

1. `balance` / `cred`. → Current balance from your default cache.
2. `caches`. → Your cache list; `cache` subcommands per help.
3. `transfer`/`tx` a small amount to the second account (per help
   syntax). → Both balances update; transaction appears in the CRED
   tab and admin → Transactions with a tx hash.

## Steps — mining/charge (if rig owned)

4. `rig` → rig status (CPU/GPU/PSU/RAM components). `charge`/mining
   flow per help: start a mining action. → Energy/heat mechanics
   apply; rewards mint on completion (CRED log shows a mining mint).

## Steps — shops (terminal path)

5. In the vendor room: `shop`. → Listings with prices. `buy <item>`,
   `sell <item>`. → Matches the panel behavior (article 35); CRED and
   inventory agree.

## Steps — fabrication + salvage

6. `schematics` / `schematic <name>`. → Known schematics + material
   requirements; READY when materials held.
7. `fabricate <schematic>` with materials. → Materials consumed, item
   created (inventory), output confirms; without materials → clear
   rejection listing what's missing.
8. `salvage <item>` on a salvageable item. → Item destroyed, salvage
   yields granted; a unicorn (unique) item refuses salvage.
9. `repair <item>` if damage mechanics apply to something you hold. →
   Cost + repair applied.

## Steps — dens (player housing)

10. `den` → your den status; `home` → travel to den (if unlocked).
11. `rename <name>` / `describe <text>` in your den. → Name/description
    update in look output.
12. `invite <other alias>`; other account visits within the hour. →
    Entry allowed; `uninvite` revokes; expired invites (1hr) deny.
13. `lock` / `unlock`. → Non-invited entry blocked/allowed accordingly.
14. Storage fixtures: `place <fixture>` in the den, `store <item>` /
    `retrieve <item>`. → 16-slot floor storage works; `unplace`
    returns the fixture.

## Steps — equipment

15. `equip`/`unequip` across a few slot types; `use` a consumable
    (vitals change); `install`/`uninstall` deck software;
    `load`/`unload` where applicable. → Loadout/deck tabs agree after
    each.
