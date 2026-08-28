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

13. Visit `/schedule`. → Upcoming streams with local-time rendering
    (times shown in YOUR timezone — check against a known UTC value);
    past broadcasts with durations; `[VOD]` links on past streams that
    have one.
