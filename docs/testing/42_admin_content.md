---
title: Admin — Logs, Codex, Handbook
area: Admin
minutes: 20
---
# Admin — Content (Hackr Logs, Codex, Handbook)

## Steps — hackr logs

1. `/root` → Logs. → Index. Create a TEST log (title "TEST DELETE ME",
   markdown body with a heading + `[[codex link]]`). → Appears in
   admin index AND on public `/logs` (published state per form).
2. Open it publicly. → Markdown + codex link render.
3. Edit the body; verify the public page updates. Check History
   (PaperTrail) shows both versions.
4. Delete the test log. → Gone from both.

## Steps — codex

5. Codex Entries index. → All entries with types. Create a TEST entry
   (type of your choice, summary + content). → Appears on `/codex`
   under its type; `[[TEST entry]]` references from other content
   resolve to it.
6. Edit + verify + delete (confirm it 404s publicly after).

## Steps — handbook

7. Handbook → Sections: create a TEST section. Articles: create a TEST
   article in it. → Public `/handbook` shows the section + article;
   article markdown renders.
8. Reorder (position fields) — move the test article/section. → Public
   order changes.
9. Delete the test article + section. → Gone publicly.

## Notes

Content connected to achievements/codex-links elsewhere should never be
casually deleted — only ever delete the TEST records you created.
