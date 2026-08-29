---
title: API Spot Checks (curl)
area: Integrations
minutes: 15
---
# API Spot Checks

Quick curl-level verification of the standing API surface. Replace
`$HOST`, `$TOKEN` (admin Bearer: `alias:raw_token`), and cookies as
needed. These duplicate what the UIs exercise — use for fast triage.

## Public reads

```sh
curl -s $HOST/api/world_events | head -c 300          # world events JSON
curl -s $HOST/api/overlay/now-playing                  # now playing
curl -s $HOST/api/overlay/alerts/pending               # alert queue
curl -s $HOST/api/profiles/SOME_ALIAS                  # public profile
```
→ All 200 with sane JSON; unknown alias → 404.

## Programmatic grid client (session-based)

```sh
# login (captures cookie)
curl -s -c /tmp/cj -X POST $HOST/api/grid/login \
  -H 'Content-Type: application/json' \
  -d '{"hackr_alias":"OPERATIVE","password":"..."}'
# command (envelope: success/output/room_id/current_room/in_breach/breach_meta)
curl -s -b /tmp/cj -X POST $HOST/api/grid/command \
  -H 'Content-Type: application/json' -d '{"input":"look"}'
# identity + logout
curl -s -b /tmp/cj $HOST/api/grid/current_hackr
curl -s -b /tmp/cj -X DELETE $HOST/api/grid/disconnect
```
→ Login honors 2FA (`requires_totp`) and disabled accounts (403);
command envelope has ALL fields above; CSRF exemption applies only
where designed.

## Admin Bearer ops

```sh
H='Authorization: Bearer ALIAS:RAW_TOKEN'
curl -s -H "$H" $HOST/api/admin/capabilities
curl -s -H "$H" $HOST/api/admin/stats
curl -s -H "$H" -X POST $HOST/api/admin/uplink/send_packet \
  -H 'Content-Type: application/json' \
  -d '{"channel_slug":"ambient","content":"api spot check"}'
curl -s -H "$H" -X POST $HOST/api/grid/debit \
  -H 'Content-Type: application/json' \
  -d '{"hackr_alias":"OPERATIVE","amount":1,"memo":"test guide"}'
```
→ All 200; a WRONG token → 401 on every admin endpoint; rate-limit
headers/endpoint behave per config.

## Collectors (fire-and-forget)

Browser-originated only — verify via the network tab during normal
browsing: `POST /api/error_report`, `POST /api/perf/metrics`,
`POST /api/analytics/events` return 2xx.

## Retired surface (must 404)

```sh
curl -s -o /dev/null -w '%{http_code}\n' $HOST/api/settings
curl -s -o /dev/null -w '%{http_code}\n' $HOST/api/codex
curl -s -o /dev/null -w '%{http_code}\n' $HOST/api/grid/achievements
curl -s -o /dev/null -w '%{http_code}\n' $HOST/api/uplink/channels
curl -s -o /dev/null -w '%{http_code}\n' $HOST/api/totp/status
```
→ Every retired endpoint 404s (regression check that the Phase 7
surface stays retired).
