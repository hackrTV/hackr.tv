---
title: Content Pages — Logs, Codex, Handbook, Code, Timeline, Schedule
area: Content
minutes: 20
---
# Content Pages

## Hackr Logs (/logs)

1. Visit `/logs`. → Log index with excerpts (markdown stripped),
   dates shifted to the 2126 setting.
2. Open a log. → Full markdown renders (headings, code, links);
   `[[codex]]` refs link into the codex; internal links navigate
   in-tab via Turbo; external links open new-tab.
3. Read-state: as a logged-in hackr, opening a log marks it read
   (unread markers on the index update).

## Codex (/codex)

4. Visit `/codex`. → Entry index grouped/filterable by type (7 types).
5. Open an entry (e.g. `the-ride`). → Renders with type accent +
   metadata; `[[links]]` to other entries resolve.
6. A bogus slug `/codex/nope`. → Clean 404.

## Handbook (/handbook)

7. Visit `/handbook`. → Sections with articles (~34 across 8 sections).
8. Open an article. → Markdown renders; section nav present;
   cross-links work.

## Code browser (/code)

9. Visit `/code`. → Repo list with last-sync dates (relative "3d ago"
   style).
10. Open a repo → tree → a file blob. → Rouge-highlighted source with
    the language detected; file size formatted; binary files handled
    (no garbage render).
11. Deep path + branch handling: nested directories navigate correctly;
    breadcrumbs work.

## Timeline (/timeline)

12. Visit `/timeline`. → Interactive timeline renders; era labels
    correct; side tabs (desktop) or inline tabs (mobile) switch
    content; global feed scrolls/loads more.

## Schedule (/schedule)

13. Visit `/schedule`. → A console screen: the lines flick on (a key
    or click skips), bar `SCHEDULE` with `[<] HOME` / `[>] VIDZ`, no
    ASCII banner. Status rows: SIGNAL (`● LIVE NOW` + the live title
    linking `/`, else STANDBY), NEXT TX (stamp · title · artist ·
    `T-MINUS …` ticking each second, else UNSCHEDULED), LAST TX (stamp ·
    title · artist, the title linking the recording with `· VOD` when it
    has one, else NO RECORD). Stamps read `YYYY-MM-DD HH:MM` a century
    ahead, in the server's Central time, not the viewer's.
14. `// UPCOMING //` rows: stamp, UPCOMING (cyan) or STARTING SOON
    (amber, within the hour after the scheduled time), title · artist;
    cancelled and expired streams are absent. With a stream scheduled a
    minute out, NEXT TX flips to `STARTING SOON!` in orange at zero.
15. `// PAST BROADCASTS //` rows: stamp, duration, title · artist,
    `[>] VOD` on TCP / XERAEN recordings only (other artists'
    recordings have no page, so no link). Hovering a row with a
    `[>] VOD` (or tabbing to its link) lights the whole row; rows
    without one stay unlit. Empty ledgers read NO
    TRANSMISSIONS SCHEDULED / NO BROADCASTS ON RECORD.
16. At the `>` prompt: `?` lists `home vidz tcp xeraen · clear`; `vidz`
    Enter opens the archive with the player still playing. Under 768px
    each row stacks (stamp + state / duration + VOD over the title).
