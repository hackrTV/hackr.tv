# hackr.tv Admin API Spec

*Spec for the `/api/admin` namespace enabling Echo (Clawdbot) to manage hackr.tv operations.*

**Status:** Ready for implementation
**Date:** 2026-01-28
**Consumer:** Echo via `hackr-cli` (see `~/dev/echo_skills/hackr-tv/`)

---

## Overview

A new `Api::Admin` namespace providing programmatic access to hackr.tv admin operations. Uses a **separate admin token** (not Grid Hackr session auth) and supports acting **on behalf of any hackr alias**.

---

## 1. Authentication

### Admin Token

A standalone bearer token, separate from Grid Hackr tokens.

**Header:** `Authorization: Bearer <admin_token>`

**Implementation Options (pick one):**
- **A) ENV-based:** Single token via `HACKR_ADMIN_API_TOKEN` env var. Simple, sufficient for a single consumer (Echo).
- **B) DB-backed:** `AdminApiToken` model with `token`, `name`, `rate_limit`, `created_at`, `last_used_at`, `revoked_at`. More flexible if you ever want multiple consumers or per-token rate limits.

**Recommendation:** Option A for now, migrate to B if needed later.

### Base Controller

```ruby
# app/controllers/api/admin/base_controller.rb
module Api
  module Admin
    class BaseController < ApplicationController
      before_action :authenticate_admin_token!
      before_action :enforce_rate_limit!

      private

      def authenticate_admin_token!
        token = request.headers["Authorization"]&.sub(/\ABearer\s+/, "")
        expected = ENV["HACKR_ADMIN_API_TOKEN"].presence

        unless expected && ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)
          render json: { success: false, error: "Unauthorized" }, status: :unauthorized
        end
      end

      def resolve_hackr!(alias_param = params[:hackr_alias])
        @acting_hackr = GridHackr.find_by!(hackr_alias: alias_param)
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: "Hackr not found: #{alias_param}" }, status: :not_found
      end

      def enforce_rate_limit!
        # See Section 7: Rate Limiting
      end
    end
  end
end
```

---

## 2. Streams

Wraps existing `HackrStream` model methods (`go_live!`, `end_stream!`).

### `GET /api/admin/streams/status`

Returns current stream state for all artists.

**Response:**
```json
{
  "is_live": true,
  "stream": {
    "id": 1,
    "artist": { "id": 1, "name": "The.CyberPul.se", "slug": "thecyberpulse" },
    "title": "Enter The Hackr Hangar",
    "live_url": "https://www.youtube.com/embed/abc123",
    "started_at": "2026-01-28T18:00:00Z"
  }
}
```

When no stream is live: `{ "is_live": false, "stream": null }`

### `POST /api/admin/streams/go_live`

Starts a livestream. Ends any currently live streams first.

**Request Body:**
```json
{
  "artist_slug": "thecyberpulse",
  "live_url": "https://youtube.com/live/abc123",
  "title": "Enter The Hackr Hangar 47"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `artist_slug` | string | ✅ | Artist slug (e.g., `thecyberpulse`, `xeraen`) |
| `live_url` | string | ✅ | YouTube/stream URL (auto-converts to embed format) |
| `title` | string | ❌ | Stream title (max 255 chars) |

**Behavior:**
1. Find artist by slug (404 if not found)
2. End any currently live streams (`HackrStream.live.find_each(&:end_stream!)`)
3. Create a new `HackrStream` for the artist and call `go_live!`
4. This triggers the existing `broadcast_stream_status` Action Cable broadcast

**Success Response (201):**
```json
{
  "success": true,
  "message": "Stream is now LIVE",
  "stream": {
    "id": 42,
    "artist_slug": "thecyberpulse",
    "title": "Enter The Hackr Hangar 47",
    "live_url": "https://www.youtube.com/embed/abc123",
    "started_at": "2026-01-28T18:00:00Z"
  }
}
```

### `POST /api/admin/streams/end`

Ends the current livestream for an artist.

**Request Body:**
```json
{
  "artist_slug": "thecyberpulse"
}
```

**Behavior:**
1. Find the currently live stream for the given artist
2. Call `end_stream!` on it
3. If no live stream found for that artist, return 404

**Success Response (200):**
```json
{
  "success": true,
  "message": "Stream ended",
  "stream": {
    "id": 42,
    "artist_slug": "thecyberpulse",
    "ended_at": "2026-01-28T20:30:00Z"
  }
}
```

---

## 3. Hackr Logs

Currently read-only in the API. Needs `create` and `update`.

### `GET /api/admin/hackr_logs`

List hackr logs (can reuse existing `Api::LogsController#index` logic).

**Query Params:** `page`, `per_page` (same as existing)

### `POST /api/admin/hackr_logs`

Create and publish a new hackr log.

**Request Body:**
```json
{
  "hackr_alias": "XERAEN",
  "title": "Signal Update",
  "body": "Markdown content here...",
  "published": true
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `hackr_alias` | string | ✅ | Author identity |
| `title` | string | ✅ | Log title |
| `body` | string | ✅ | Markdown body |
| `published` | boolean | ❌ | Default: `true` |

**Behavior:**
1. Resolve hackr by alias (404 if not found)
2. Auto-generate `slug` from title (parameterize, ensure uniqueness)
3. Set `published_at` to now if `published: true`
4. Create `HackrLog` record

**Success Response (201):**
```json
{
  "success": true,
  "message": "Hackr log created",
  "log": {
    "id": 1,
    "title": "Signal Update",
    "slug": "signal-update",
    "published": true,
    "published_at": "2026-01-28T12:00:00Z",
    "author": {
      "id": 1,
      "hackr_alias": "XERAEN"
    }
  }
}
```

### `PATCH /api/admin/hackr_logs/:slug`

Update an existing hackr log.

**Request Body (all fields optional):**
```json
{
  "title": "Updated Title",
  "body": "Updated markdown content..."
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Hackr log updated",
  "log": { ... }
}
```

---

## 4. PulseWire

Wraps existing `Pulse` and `Echo` models but authenticates via admin token and acts on behalf of a hackr.

### `POST /api/admin/pulses`

Post a pulse on behalf of a hackr.

**Request Body:**
```json
{
  "hackr_alias": "XERAEN",
  "content": "The signal continues. 100 years of resistance compressed into electromagnetic pulses."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `hackr_alias` | string | ✅ | Posting identity |
| `content` | string | ✅ | Max 256 characters |

**Behavior:**
1. Resolve hackr by alias
2. Create `Pulse` with `grid_hackr: hackr`, `content: content`, `pulsed_at: Time.current`
3. Profanity filter still applies (existing model validation)

**Success Response (201):**
```json
{
  "success": true,
  "message": "Pulse broadcast successfully",
  "pulse": {
    "id": 1,
    "content": "The signal continues...",
    "pulsed_at": "2026-01-28T12:00:00Z",
    "grid_hackr": {
      "id": 1,
      "hackr_alias": "XERAEN",
      "role": "admin"
    }
  }
}
```

### `POST /api/admin/pulses/:id/echo`

Echo a pulse on behalf of a hackr.

**Request Body:**
```json
{
  "hackr_alias": "Ryker"
}
```

**Behavior:**
- Same toggle logic as existing `Api::EchoesController#create`
- Uses the resolved hackr instead of `current_hackr`

### `POST /api/admin/pulses/:id/splice`

Reply to a pulse on behalf of a hackr.

**Request Body:**
```json
{
  "hackr_alias": "Synthia",
  "content": "Frequency analysis complete. Probability of exploitable gap: increasing."
}
```

**Behavior:**
1. Resolve hackr by alias
2. Create `Pulse` with `parent_pulse_id: params[:id]`, setting `thread_root_id` as existing model logic handles
3. Max 256 chars, profanity filter applies

---

## 5. Uplink

Wraps existing packet creation but authenticates via admin token.

### `POST /api/admin/uplink/:channel_slug/send`

Send a packet to an Uplink channel.

**Request Body:**
```json
{
  "hackr_alias": "XERAEN",
  "content": "Signal check. All frequencies operational."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `hackr_alias` | string | ✅ | Sender identity |
| `content` | string | ✅ | Message content |

**Behavior:**
1. Resolve channel by slug (404 if not found)
2. Resolve hackr by alias
3. **Skip** punishment checks (squelch/blackout) — admin API bypasses moderation
4. **Skip** slow mode — admin API is not rate-limited per-channel
5. Create `ChatMessage` with `grid_hackr: hackr`, `content: content`
6. Broadcast via Action Cable as normal

**Success Response (201):**
```json
{
  "success": true,
  "message": "Packet transmitted",
  "packet": {
    "id": 1,
    "content": "Signal check...",
    "created_at": "2026-01-28T12:00:00Z",
    "grid_hackr": {
      "id": 1,
      "hackr_alias": "XERAEN"
    }
  }
}
```

---

## 6. Pulse Grid (Low Priority)

### `POST /api/admin/grid/connect`

Connect a hackr to the Grid.

**Request Body:**
```json
{
  "hackr_alias": "XERAEN"
}
```

**Behavior:**
1. Resolve hackr by alias
2. Set session/presence as connected (touch activity)
3. Return current room info

### `POST /api/admin/grid/command`

Execute a Grid command on behalf of a hackr.

**Request Body:**
```json
{
  "hackr_alias": "XERAEN",
  "command": "look"
}
```

**Behavior:**
- Same as existing `Api::GridController#command` but using resolved hackr
- Touch activity, parse command, broadcast events

### `POST /api/admin/grid/disconnect`

Disconnect a hackr from the Grid.

**Request Body:**
```json
{
  "hackr_alias": "XERAEN"
}
```

---

## 7. Rate Limiting

### Implementation

A `before_action` on `Api::Admin::BaseController` using Rails cache:

```ruby
def enforce_rate_limit!
  key = "admin_api_rate_limit:#{request.remote_ip}"
  count = Rails.cache.increment(key, 1, expires_in: 1.minute, initial: 0)

  limit = (ENV["ADMIN_API_RATE_LIMIT"] || 125).to_i

  response.set_header("X-RateLimit-Limit", limit)
  response.set_header("X-RateLimit-Remaining", [limit - count, 0].max)
  response.set_header("X-RateLimit-Reset", 1.minute.from_now.to_i)

  if count > limit
    render json: {
      success: false,
      error: "Rate limit exceeded. Try again later.",
      limit: limit,
      retry_after: 60
    }, status: :too_many_requests
  end
end
```

### `GET /api/admin/rate_limit`

Check current rate limit status.

**Response:**
```json
{
  "limit": 125,
  "remaining": 118,
  "resets_at": "2026-01-28T12:01:00Z"
}
```

### Configuration

- Default: 125 requests/minute
- Override via `ADMIN_API_RATE_LIMIT` env var
- **Future:** Expose in admin web UI via an `AppSetting` record

---

## 8. Capabilities

### `GET /api/admin/capabilities`

Returns available admin API features and their status. Useful for the CLI to discover what's implemented.

**Response:**
```json
{
  "version": "1.0",
  "capabilities": {
    "streams": { "status": true, "go_live": true, "end": true },
    "hackr_logs": { "list": true, "create": true, "update": true },
    "pulses": { "create": true, "echo": true, "splice": true },
    "uplink": { "send": true },
    "grid": { "connect": true, "command": true, "disconnect": true }
  }
}
```

---

## 9. Routes

```ruby
# config/routes.rb — add inside the existing `namespace :api` block

namespace :admin do
  # Streams
  get  "streams/status", to: "streams#status"
  post "streams/go_live", to: "streams#go_live"
  post "streams/end", to: "streams#end_stream"

  # Hackr Logs
  get  "hackr_logs", to: "hackr_logs#index"
  post "hackr_logs", to: "hackr_logs#create"
  patch "hackr_logs/:slug", to: "hackr_logs#update"

  # PulseWire
  post "pulses", to: "pulses#create"
  post "pulses/:id/echo", to: "pulses#echo"
  post "pulses/:id/splice", to: "pulses#splice"

  # Uplink
  post "uplink/:channel_slug/send", to: "uplink#send_packet"

  # Grid (low priority)
  post "grid/connect", to: "grid#connect"
  post "grid/command", to: "grid#command"
  post "grid/disconnect", to: "grid#disconnect"

  # Meta
  get "capabilities", to: "meta#capabilities"
  get "rate_limit", to: "meta#rate_limit"
end
```

---

## 10. Error Format

All errors follow a consistent format:

```json
{
  "success": false,
  "error": "Human-readable error message"
}
```

**HTTP Status Codes:**
| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 401 | Bad/missing admin token |
| 404 | Resource not found (artist, hackr, pulse, channel, etc.) |
| 422 | Validation error (content too long, missing fields, profanity filter) |
| 429 | Rate limit exceeded |
| 500 | Server error |

---

## 11. Files to Create

| File | Purpose |
|------|---------|
| `app/controllers/api/admin/base_controller.rb` | Auth + rate limiting base class |
| `app/controllers/api/admin/streams_controller.rb` | Stream management |
| `app/controllers/api/admin/hackr_logs_controller.rb` | Log CRUD |
| `app/controllers/api/admin/pulses_controller.rb` | PulseWire operations |
| `app/controllers/api/admin/uplink_controller.rb` | Uplink messaging |
| `app/controllers/api/admin/grid_controller.rb` | Grid operations (low priority) |
| `app/controllers/api/admin/meta_controller.rb` | Capabilities + rate limit |
| Route additions in `config/routes.rb` | See Section 9 |

---

## 12. Testing Checklist

- [ ] Admin token auth works (valid token → 200, missing/invalid → 401)
- [ ] Rate limiting enforces cap and returns proper headers
- [ ] `hackr_alias` resolves correctly (valid → proceeds, unknown → 404)
- [ ] Streams: go_live creates stream, ends existing, broadcasts via Action Cable
- [ ] Streams: end_stream ends correctly, returns 404 if no live stream
- [ ] Hackr Logs: create generates slug, sets published_at, validates fields
- [ ] Hackr Logs: update modifies only provided fields
- [ ] Pulses: create respects 256 char limit, profanity filter, sets pulsed_at
- [ ] Pulses: echo toggles correctly
- [ ] Pulses: splice sets parent_pulse_id and thread_root_id
- [ ] Uplink: send bypasses punishment/slow mode, creates ChatMessage, broadcasts
- [ ] Grid: connect/command/disconnect work on behalf of resolved hackr
- [ ] Capabilities: returns accurate feature list
- [ ] All endpoints return consistent error format

---

*Consumer: [[hackr-tv]] Clawdbot skill*
*Lore context: [[hackr.tv Lore Summary]]*
