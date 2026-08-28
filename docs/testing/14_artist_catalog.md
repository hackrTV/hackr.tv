---
title: Artist Catalog — Releases, Trackz, Vidz
area: Music & Player
minutes: 15
---
# Artist Catalog (releases / trackz / vidz)

## Steps — releases

1. Visit `/thecyberpulse/releases`. → Release index for the artist:
   released grid + coming-soon strip; registers a release-index view
   (achievement source) silently.
2. Open a release (`/thecyberpulse/releases/<slug>`). → Detail page:
   cover, track list, disc length; play works.
3. A release whose tracks are all vault-hidden must 404 here; a
   coming-soon release renders but does not play.
4. Numeric-id URL for the same release. → Also resolves (slug-or-id).

## Steps — trackz

5. Open a track page (`/<artist>/trackz/<slug>`). → Track detail renders
   (cover, release link, duration); play works.
6. A track belonging to a coming-soon release. → Redirects to the
   release page instead of rendering.
7. Legacy `/trackz/:id` URL (old bookmark shape). → Redirects to the
   canonical artist-scoped page.

## Steps — vidz (VODs)

8. Visit `/thecyberpulse/vidz`. → VOD list renders (only streams with a
   vod_url).
9. Open a VOD. → `/thecyberpulse/vidz/<id>` renders with the embedded
   player. While logged in, watching credits a VOD watch (feeds
   `vods_watched`) via the watch ping — check the network tab for the
   `POST .../watch` beacon.
10. Visit `/xeraen/vidz` when XERAEN has no VODs. → Bounces to
    `/thecyberpulse/vidz`.
11. From `/schedule`, click a past stream's `[VOD]` link. → Lands on the
    vidz page via Turbo (player survives).
