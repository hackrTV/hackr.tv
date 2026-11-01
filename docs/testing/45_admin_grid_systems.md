---
title: Admin — Grid Systems (Items, Shops, Missions, Breach, Transit, Factions)
area: Admin
minutes: 45
---
# Admin — Grid Systems CRUD

Every screen here is a `/root` console screen (article 42's idiom): the
bar, `[OK]` / `[ERR]` replies under it, ledgers, `// DESTINATIONS //`
(ITEMS SCHEMATICS SHOPS SALES ACHIEVEMENTS MISSIONS ARCS WIZARD BREACH
ENCOUNTERS ECONOMY TRANSACTIONS REPLOG REPUTATIONS ASSIGNMENTS IMPOUND +
ROOT) and the `>` prompt, whose commands are those tags plus the
ledger's numbers. A record IS its edit screen: saves stay on it, and
`[DELETE …]` lives only on the record (it confirms first). Create TEST
records and clean up after.

## Steps — item definitions + shops

1. `/root` → `[ITEMS]`. → `// ITEMS //` numbered (85+ on the seeded
   world, `[01]`–`[85]`), each name over its slug with TYPE, RARITY,
   VALUE and `[HISTORY]`; the TYPE row lists ALL + the 12 types. Click
   CONSUMABLE. → Only consumables, CONSUMABLE lit, ON RECORD says so;
   ALL brings the rest back. Type part of a name into FILTER. → Rows
   narrow as you type, the count reads `n / 85`; `[x] CLEAR` restores.
   Type a row number at the prompt + Enter. → The item record: IN USE
   (live items · listings · schematic uses · salvage yields — what
   refuses a delete), NAME / SLUG / TYPE / RARITY / BASE VALUE / MAX
   STACK, `// DESCRIPTION //`, `// PROPERTIES //` (the JSON object), and
   `// SALVAGE YIELDS //` rows (POS · OUTPUT ITEM · QTY · `[x]`) with a
   blank row at the end and `[+] ADD YIELD`.
2. `[+] NEW ITEM` → create a TEST item definition (cheap material,
   `{}` properties). → `[OK]`, you stay on its record. Put `{"slot": }`
   into PROPERTIES and `[SAVE ITEM]`. → `[ERR]` "is not valid JSON",
   the JSON still as you typed it; fix it back to `{}`. `[+] ADD YIELD`,
   pick an output + QTY 2, save. → The yield is on record; `[x]` on it +
   save removes it. Grant one to the operative (Hackrs → item grant, or
   the `item_grant` dev command). → Appears in inventory; `salvage`
   behaves per its yields. `[DELETE ITEM]` while the operative still
   holds one. → Confirm, then `[ERR]` "has live items or shop listings"
   on the ITEMS ledger.
3. `[SHOPS]`. → `// LISTINGS //` numbered across every vendor: item
   over vendor · type, RARITY, BUY, SELL, STOCK (`n/max`, red when sold
   out, `INF` for unlimited), CL, ACTIVE / ROT, `[RESTOCK]` (stocked
   listings only) and `[HISTORY]`; the VENDOR row narrows to one vendor
   (`[>] VENDOR` then opens its mob record). With your TEST vendor
   (article 44) selected, `[+] NEW LISTING`. → The vendor is prefilled;
   list the test item, `[CREATE LISTING]`. → `[OK]` on the listing
   record (NEXT RESTOCK, the fields under `// PRICING //` and
   `// STOCK //`, FLAGS ACTIVE / ROTATION POOL; `[>] VENDOR`, `[>] ITEM`).
   Buyable in-game. Back on SHOPS, `[RESTOCK]` it. → `[OK]` "restocked
   to N", STOCK reads `N/N`. `[DELETE LISTING]` on its record when done.
   → Confirm, then back on that vendor's listings.
4. `[SALES]` (or `[>] SALES` on SHOPS). → `// TRANSACTIONS //`, newest
   first, the latest 100: when · BUY / SELL · item over `@alias` ·
   vendor · PRICE · BURN · RECYCLE (the item opens its listing). Put the
   operative's alias into HACKR, `[FILTER]`; click BUY. → Only their
   purchases, and BUY keeps the alias. An unknown alias reads "NO HACKR
   NAMED '…'". `[x] CLEAR` shows everything again.

## Steps — achievements

5. `[ACHIEVEMENTS]`. → `// ACHIEVEMENTS //` numbered (79+ on the seeded
   world): name over `badge · slug`, CATEGORY, TRIGGER, XP, CRED,
   EARNED, HIDDEN, `[HISTORY]`. The ON RECORD line counts awards earned,
   hidden and manual achievements. Click a CATEGORY (GRID MUSIC SOCIAL
   META PROGRESSION) → the ledger narrows server-side and the button
   lights; ALL clears it. Type in FILTER (name / slug / category /
   trigger) → rows narrow, the count reads `shown / total`. Type a
   number at the prompt → the record: EARNED readout, NAME / SLUG /
   BADGE / CATEGORY / TRIGGER / XP / CRED / FLAGS (HIDDEN),
   `// DESCRIPTION //`, `// TRIGGER DATA //` (a JSON object). Change XP,
   `[SAVE ACHIEVEMENT]` → `[OK]` on the same record. Put `{"count": 1`
   (broken JSON) in TRIGGER DATA and save → 422, `[ERR] Trigger data is
   not valid JSON …`, the box still holds what you typed and the stored
   value is unchanged (it used to save `{}` silently). Restore it.
6. Back on the ledger, `// MANUAL AWARD //` lists one row per manual
   achievement (badge · name · hackr · `[AWARD]`). Pick the operative,
   `[AWARD]`. → `[OK] Awarded '…' to <alias>.`; the toast fires in-game
   (article 02) and `/achievements` shows it earned. `[AWARD]` again →
   `[ERR] <alias> already has '…'.`

## Steps — missions + arcs

7. `[MISSIONS]`. → `// MISSIONS //` numbered: name over
   `slug · after <prereq>`, ARC, GIVER, CL, OBJ, RWD, ACTIVE, DONE,
   LIVE / DRAFT (+ REP for repeatable), `[HISTORY]`; FILTER by name /
   slug / arc / giver / prereq. `[+] NEW MISSION` opens the blank record,
   `[>] WIZARD` the seven-step wizard (step 10). Create a TEST mission
   on your TEST NPC with `[+] NEW MISSION`: type in GIVER (arrow keys +
   Enter pick; the box turns green), leave ARC / PREREQ empty, fill the
   first OBJECTIVES row (TYPE, LABEL, TARGET SLUG — the legend above the
   rows says what each type's slug names) and the first REWARDS row
   (xp, AMOUNT). `[CREATE MISSION]` → `[OK]` on the new record, which
   now shows a blank row under each list. Fill the blank OBJECTIVES row
   and save → a second objective; leave a blank row's TYPE at `—` and
   it is skipped. Click `[x]` on a saved reward → the row disappears;
   save → the reward is gone. Save with GIVER cleared while PUBLISHED is
   ticked → 422, the error in red on the GIVER row, the `[x]`-ed rows
   stay hidden. Put `{"topic": "x"}` in `// DIALOGUE PATH //` → 422
   "must be a JSON array of topic keys" (blank = no gate). In-game the
   giver offers the TEST mission; run accept → progress → turn-in. The
   record's HACKRS line counts active / turned in, `[>] ASSIGNMENTS`
   opens the hackr missions log; `[>] <GIVER>` in the bar opens the mob.
8. `[ARCS]`. → `// ARCS //` numbered: name over slug, POS, MISSIONS,
   LIVE / DRAFT. An arc record (NAME / SLUG / POS / FLAGS,
   `// DESCRIPTION //`) lists its `// MISSIONS //` (a number at the
   prompt opens one) and `[+] NEW MISSION`, which opens a new mission
   with the ARC picker already filled. Rename an arc's slug and save →
   the record reloads at the new address. `[DELETE ARC]` (confirms) →
   the arc goes, its missions stay outside any arc.
9. `[ASSIGNMENTS]` (`/root/grid_hackr_missions`). → Every mission a
   hackr has taken, newest first: `[NN]` · mission over slug · hackr ·
   STATUS · accepted · completed · turn-ins. STATUS ALL / ACTIVE /
   COMPLETED links keep the HACKR filter; your TEST run from step 7 is
   listed. Type its number at the `>` prompt → `ASSIGNMENT #id`: the
   status rows, `[>] MISSION` / `[>] HACKR`, and `// OBJECTIVES //` with
   progress `n / count` and DONE per objective.
10. `[WIZARD]`. → One step at a time under the step row
    `[1] ARC … [7] REVIEW` (green = here, cyan = passed — click to go
    back, faint = skipped). `[>] NEXT` with nothing chosen on a step
    that needs it → an `[ERR]` line under the step's rule. Pick an
    existing giver in step 2 → step 3 (ROOM) is skipped. Name the
    mission in step 4 → SLUG follows the name. Step 5 `[+] ADD
    OBJECTIVE` adds a row, its `[x]` drops it; step 7 lists everything.
    Use an existing mission's slug and `[CREATE MISSION]` → 422 `[ERR]
    Slug has already been taken`, and the wizard comes back on step 7
    with everything still filled in; click `[4] MISSION`, fix the slug,
    NEXT to step 7, create → `[OK] Mission '…' created via wizard.` on
    the new mission's record. Leave the wizard half-filled, reload → a
    `[WARN]` line offers `[RESTORE]` / `[DISCARD]`. Delete the TEST
    missions after turn-in (`[DELETE MISSION]`, refused with `[ERR]`
    while a hackr has it active). → Gone from the giver and `/missions`.

## Steps — breach config

11. `[BREACH]` (`/root/grid_breach_templates`). → A console ledger of
    42+ templates: `[NN]` · name over slug · TIER · CL · PNR · XP · CRED
    · ACTIVE · LIVE / DRAFT · `[HISTORY]`; ON RECORD counts live
    templates and active breaches. Type `elite` (or a zone slug) in
    FILTER → only matching rows, the count reads `n / 42`; `[x] CLEAR`
    restores. Type a number at the `>` prompt + Enter → that template's
    record.
12. On the record: change PNR and COOLDOWN MAX, edit the PROTOCOL
    COMPOSITION JSON (add `"count": 2` to a protocol), set ZONES to two
    slugs, `[SAVE TEMPLATE]`. → Stays on the record with `[OK] Breach
    template '…' updated.` and every value kept. Break the JSON (delete
    a closing bracket) and save → 422 with `[ERR] Invalid JSON: …`, your
    broken JSON still in the textarea, nothing saved. Set PNR to 101 →
    `[ERR]` and the error beside the field. `// ENCOUNTERS //` lists the
    rooms the template is placed in (number → the encounter);
    `[+] NEW ENCOUNTER` opens a new encounter with this template already
    selected. `[DELETE TEMPLATE]` on a template that is placed in a room
    → confirm → back on the ledger with `[ERR] Cannot delete …` (no
    crash).
13. `[ENCOUNTERS]` (`/root/grid_breach_encounters`). → A console ledger
    of the placements: `[NN]` · room over zone · template over tier ·
    STATE · ACTIVE · COOLDOWN · `[RESET]` `[HISTORY]`; the one you fought
    in article 36 is listed. Type `cooldown` in FILTER → only the
    encounters cooling down. `[RESET]` on a cooling or depleted row →
    confirm → `[OK] Encounter '…' set to available.`, the row reads
    AVAILABLE and loses its `[RESET]`.
14. Open an encounter → TEMPLATE / ROOM / STATE / SEED rows,
    `[>] TEMPLATE` and `[>] <ROOM>` in the bar, `// META //` (cooldown,
    active breaches, created). Change the state, `[SAVE ENCOUNTER]` →
    stays on the record with `[OK] Encounter updated.` Try placing the
    same template in the same room a second time from `[+] NEW
    ENCOUNTER` → 422, `already placed in this room` beside the template.
    Delete the TEST placement with `[DELETE ENCOUNTER]` → confirm → back
    on the ledger.

## Steps — transit config

15. Grid → Transit Types / Transit Routes / Slipstream / Journeys. →
    Types (13 vehicle types), routes with stops + fares, slipstream
    legs, journey log of your article-35 ride.
16. Create a TEST local route between two stops (inline stop
    management), verify it appears on the in-game departure board,
    then delete it.

## Steps — factions + schematics

17. Grid → Factions. → 7 factions with rep tier config. `[REPUTATIONS]`
    (`/root/grid_hackr_reputations`, also `[>] REPUTATIONS` on the rep
    log): `// STANDINGS //` per hackr per faction (+ green, - red); HACKR
    / FACTION filter. `// ADJUST //`: the operative, a leaf faction
    (aggregates are not offered), DELTA 5, a NOTE → `[APPLY]` → `[OK]
    <alias> :: <faction> +5 > <value> (<tier>)` under the bar and the
    standing moves; DELTA 0 → `[ERR] Delta must be non-zero.` Then
    `[REPLOG]` (`/root/grid_reputation_events`): the adjustment is the
    newest event (DELTA, AFTER, reason `admin:manual` over your note,
    source); filter by HACKR / FACTION / a REASON prefix (`admin:`).
18. `[SCHEMATICS]`. → `// SCHEMATICS //` numbered (29 on the seeded
    world) in fabrication order: name over slug, OUTPUT `xQTY`, INGR,
    XP, CL, LIVE / DRAFT, `[HISTORY]` — matching the in-game
    `schematics` output. Open one. → NAME / SLUG / OUTPUT / OUTPUT QTY
    / XP / CLEARANCE / POSITION, FLAGS PUBLISHED, `// DESCRIPTION //`,
    `// GATES //` (MISSION / ACHIEVEMENT slugs, ROOM TYPE), and
    `// INGREDIENTS //` rows (POS · INPUT ITEM · QTY · `[x]`) with
    `[+] ADD INGREDIENT`; `[>] OUTPUT` opens the output item. Add an
    ingredient row, save, then `[x]` it and save again. → `[OK]` each
    time, the ingredient on record and then gone. Don't delete a seeded
    schematic.
