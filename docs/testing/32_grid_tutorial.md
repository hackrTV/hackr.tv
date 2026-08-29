---
title: Grid Tutorial (Bootloader)
area: The Grid
minutes: 30
---
# Grid Tutorial — Bootloader (fresh account)

The 53-step Bootloader onboarding. Needs the FRESH account with
`pulse_grid` granted but tutorial NOT completed.

## Steps

1. Grant `pulse_grid` to the fresh account (admin → Hackrs → grants),
   leave `tactical_grid` off.
2. Log in as fresh; visit `/grid`. → The tutorial bootstraps
   automatically: Bootloader intro output, guided first step.
3. Follow the guided prompts in order (the tutorial tells you each next
   command: look, movement, take, equip, say, etc.). Verify at each
   step: instruction → your command → acknowledgment + next
   instruction. Work through to completion. Spot-verify:
   - Wrong commands mid-tutorial get corrective guidance, not crashes.
   - Progress survives a page reload mid-tutorial (resumes at the same
     step).
   - Vitals/XP awarded along the way appear in `stat`.
4. Completion. → Clear completion message; `tutorial_completed` set
   (admin → Hackrs → the hackr's stats); normal play unlocked.
5. Revisit `/grid`. → No tutorial re-trigger; normal welcome.
6. Note total time + any step whose instructions felt wrong in the run
   notes (this article is also a content-QA pass over the tutorial
   copy).
