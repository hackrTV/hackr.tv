---
title: Admin — Logs, Codex, Handbook, Emotes
area: Admin
minutes: 25
---
# Admin — Content (Hackr Logs, Codex, Handbook, Emotes)

Every screen here is a `/root` console screen (the music screens' idiom,
article 41): a bar, `[OK]` / `[ERR]` replies under it, numbered `[NN]`
ledger rows, `// DESTINATIONS //` (the content section's tags + `[ROOT]`)
and the `>` prompt. The record screen IS the edit screen — opening a
record's plain URL (`/root/hackr_logs/<slug>`) lands on its edit
screen, a save stays on it with `[OK]`, and the delete is the
`[DELETE …]` ghost button at the end of `// COMMIT //` (confirm dialog).
No TuiCss window, table or button anywhere.

## Steps — hackr logs

1. `/root` → Logs. → The `LOGS` ledger: ON RECORD (live / draft
   counts), a FILTER row, `[NN]` rows (title over slug · @author ·
   timeline, LIVE / DRAFT, published date, `[EDIT] [HISTORY]`). Type a
   few letters of a title in FILTER. → Rows narrow live, the count reads
   `n / total`; `[x] CLEAR` restores them. Type `new` at the prompt. →
   NEW LOG.
2. Create a TEST log (title "TEST DELETE ME", markdown body with a
   heading + `[[codex link]]`, PUBLISHED). → `[CREATE LOG]` opens its
   record with `[OK]`; the bar shows `[>] PUBLIC` (published only). Open
   it publicly. → Markdown + codex link render.
3. Edit the body, `[SAVE LOG]`. → Stays on the record, `[OK]`; the public
   page updates. `[HISTORY]` shows both versions.
4. Blank the TITLE and save. → 422: `[ERR]` under the bar, the form still
   posts to the saved slug.
5. `[DELETE LOG]` → confirm. → Back on the ledger with `[OK]`; gone
   publicly.

## Steps — codex

6. Codex. → The `CODEX` ledger with a TYPE row (`ALL` + the nine types)
   and FILTER. Click `ORGANIZATION`. → Only organizations, the button
   lit. Create a TEST entry (summary + content; leave SLUG blank). → The
   record opens at the slug made from the name; `/codex` lists it under
   its type; `[[TEST entry]]` references resolve to it.
7. Put `{nope` in `// METADATA //` and save. → 422 `[ERR] … is not valid
   JSON`. Fix it to `{"x": 1}`, save. → `[OK]`.
8. Delete the entry (confirm). → 404s publicly after.

## Steps — handbook

9. Handbook → Sections. → The `SECTIONS` ledger in handbook order with
   article counts and `[ARTICLES] [EDIT] [HISTORY]` per row. Create a
   TEST section. → Its record opens with an empty `// ARTICLES //` and
   `[+] NEW ARTICLE`.
10. `[+] NEW ARTICLE` (or type `new`). → NEW ARTICLE with the SECTION
    preselected. Create it. → Its record opens; `[<] ARTICLES` lands on
    the articles ledger filtered to that section. Public `/handbook`
    shows section + article; the markdown renders.
11. Articles ledger: one `// SECTION //` rule per section, rows numbered
    through; the SECTION row narrows server-side, FILTER client-side
    (a section whose rows all miss hides).
12. Reorder (POSITION fields). → Public order changes.
13. Delete the TEST article, then the TEST section (its confirm names the
    article count). → Gone publicly.

## Steps — emotes

14. Emotes. → The `EMOTES` ledger: each emote as chat draws it (28px
    tall), token over the image facts, ENABLED / DISABLED. Create a TEST
    emote (`[^] UPLOAD IMAGE`, a PNG). → Its record: the IMAGE row shows
    it `in chat: :slug:` with type / size / dimensions.
15. `[x] REMOVE IMAGE` → confirm. → `[OK]`, NO IMAGE. Upload a JPEG. →
    422 `[ERR]`, IMAGE reads UPLOAD REJECTED, nothing 500s.
16. Delete the TEST emote (confirm).

## Notes

Content connected to achievements/codex-links elsewhere should never be
casually deleted — only ever delete the TEST records you created.
