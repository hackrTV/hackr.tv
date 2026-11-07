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

9. Visit `/code` (logged in). → A console screen at 1400px, no ASCII
   banner, no boot flicker: bar `CODE` with `[<] HOME`, REPOS (count ·
   languages) and SYNC (stamp a century ahead) rows, a FILTER row, then
   `// REPOSITORIES //` as `[NN]` rows (name over LANGUAGE · ★ stars ·
   pushed stamp · size, the description beside). Typing in FILTER hides
   rows that do not match name / description / language and the count
   reads `shown / total`; `[x] CLEAR` restores. At the `>` prompt type
   `01` + enter → the first repo opens; `?` lists `01 02 … home`.
10. A repo root. → Bar `<name>` · `<branch> · ROOT` with `[<] CODE`
    only; REPO (the GitHub link · description), PATH (`code / repo`),
    SYNC (stamp · n entries) and FILTER rows; `// TREE //` rows:
    directories first with a trailing `/`, files with their size,
    a submodule dim and unlinked. A root `README.md` renders below the
    tree under `// README //`; on hackr.tv its `docs/IMPORT_README.md`
    and `UNLICENSE` links open those files. Open a directory → the bar gains `[^] UP`
    and the tree a `[..]` row; both answer `..` at the prompt and go to
    the parent (the repo root from a first-level directory). PATH's
    segments are links, the last one plain.
11. A file. → FILE (the path as links), SIZE (`28.3 KB · 812 lines ·
    RUBY`) and SYNC rows, then `// SOURCE //`: a gutter of line numbers
    beside Rouge-highlighted lines on the console palette: keywords
    violet, types and constants cyan, strings green, numbers amber,
    comments grey, no inset background behind the code (the pane is one
    black surface with the gutter). Click a gutter number → the URL gains
    `#L12` and that line is tinted; reload keeps it. A `.md` file renders
    as markdown under `// MARKDOWN //`. `README.md`, `Gemfile`,
    `package.json`, a `.css` or `.txt` file all open (uppercase and
    extensions are kept — neither downcased nor treated as a format). A
    binary (`favicon.ico`) → `// CANNOT DISPLAY //` with `[^] UP`; a bogus
    path → `// SIGNAL LOST //`, 404. A file past 256 KB shows
    `NOT HIGHLIGHTED` and plain lines.
12. No reloads: start a track in the player, then `/code` → a repo → a
    directory → a file → `[<] CODE`. → The track keeps playing throughout
    (the rouge stylesheet is in every page's tracked set, so Turbo never
    hard-reloads). The second open of the same file is near-instant (the
    highlighted fragment is cached by content).

## Timeline (/timeline)

13. Visit `/timeline`. → Interactive timeline renders; era labels
    correct; side tabs (desktop) or inline tabs (mobile) switch
    content; global feed scrolls/loads more.

## Schedule (/schedule)

14. Visit `/schedule`. → A console screen: the lines flick on (a key
    or click skips), bar `SCHEDULE` with `[<] HOME` / `[>] VIDZ`, no
    ASCII banner. Status rows: SIGNAL (`● LIVE NOW` + the live title
    linking `/`, else STANDBY), NEXT TX (stamp · title · artist ·
    `T-MINUS …` ticking each second, else UNSCHEDULED), LAST TX (stamp ·
    title · artist, the title linking the recording with `· VOD` when it
    has one, else NO RECORD). Stamps read `YYYY-MM-DD HH:MM` a century
    ahead, in the server's Central time, not the viewer's.
15. `// UPCOMING //` rows: stamp, UPCOMING (cyan) or STARTING SOON
    (amber, within the hour after the scheduled time), title · artist;
    cancelled and expired streams are absent. With a stream scheduled a
    minute out, NEXT TX flips to `STARTING SOON!` in orange at zero.
16. `// PAST BROADCASTS //` rows: stamp, duration, title · artist,
    `[>] VOD` on TCP / XERAEN recordings only (other artists'
    recordings have no page, so no link). Hovering a row with a
    `[>] VOD` (or tabbing to its link) lights the whole row; rows
    without one stay unlit. Empty ledgers read NO
    TRANSMISSIONS SCHEDULED / NO BROADCASTS ON RECORD.
17. At the `>` prompt: `?` lists `home vidz tcp xeraen · clear`; `vidz`
    Enter opens the archive with the player still playing. Under 768px
    each row stacks (stamp + state / duration + VOD over the title).
