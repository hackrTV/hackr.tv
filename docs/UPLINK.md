# Uplink

Real-time chat system for hackr.tv with channel-based communication.

**Status:** Planned

---

## Overview

Uplink is a real-time chat feature that allows operatives to communicate across two channels:

- **#ambient** — Always available, persistent background chatter
- **#live** — Active only during livestreams, displayed alongside the stream

Anonymous users cannot see or access Uplink. Authentication is required.

---

## Terminology

| Term | Definition |
|------|------------|
| **Uplink** | The chat feature/system |
| **Packet** | A single chat message |
| **#ambient** | Always-on channel for general discussion |
| **#live** | Livestream-only channel, active when stream is live |
| **Operative** | Regular user |
| **Operator** | Moderator role (can warn, drop, squelch) |
| **Admin** | Full control (all moderation + configuration) |

### Moderation Actions

| Action | Effect | Duration |
|--------|--------|----------|
| **Warning** | Heads up to user, no restriction | — |
| **Drop** | Single packet removed | — |
| **Squelch** | User cannot send packets | Short-term (5-30 min) |
| **Blackout** | User cut off from Uplink entirely | Long-term / permanent |

---

## Channels

### #ambient

- Always available when logged in
- Persistent packet history (loads last 20 on join)
- General discussion, not tied to any stream

### #live

- Only available when a livestream is active on the homepage
- Activates when `HackrStream.current_live` exists
- Lingers for 15 minutes after stream ends, then closes
- Fresh packet history each stream (archived after stream ends)
- Displayed in a side panel next to the livestream embed

---

## User Roles

| Role | Permissions |
|------|-------------|
| **Operative** | Send packets, view channels |
| **Operator** | + Warn, drop packets, squelch users |
| **Admin** | + Blackout users, configure channels, view moderation log |

The role hierarchy extends the existing `GridHackr.role` field:
- `operative` (default)
- `operator` (new)
- `admin` (existing)

---

## Data Models

### ChatChannel

Admin-configurable channel settings.

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Primary key |
| `slug` | string | Unique identifier (`ambient`, `live`) |
| `name` | string | Display name |
| `description` | string | Channel description |
| `is_active` | boolean | Kill switch for channel |
| `requires_livestream` | boolean | Only active when stream is live |
| `slow_mode_seconds` | integer | Rate limit (0 = disabled) |
| `minimum_role` | string | Minimum role to send packets |
| `created_at` | datetime | — |
| `updated_at` | datetime | — |

### ChatMessage (Packet)

Individual chat messages.

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Primary key |
| `chat_channel_id` | integer | FK to ChatChannel |
| `grid_hackr_id` | integer | FK to sender |
| `hackr_stream_id` | integer | FK to stream (nullable, for #live context) |
| `content` | text | Message content (max 512 chars) |
| `created_at` | datetime | — |

Includes `ProfanityFilterable` concern for content validation.

### ModerationLog

Audit trail for moderation actions.

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Primary key |
| `actor_id` | integer | FK to GridHackr (moderator) |
| `target_id` | integer | FK to GridHackr (target user) |
| `chat_message_id` | integer | FK to dropped packet (nullable) |
| `action` | string | `warning`, `drop`, `squelch`, `blackout` |
| `reason` | text | Moderator-provided reason |
| `duration_minutes` | integer | For squelch/blackout (nullable) |
| `created_at` | datetime | — |

### UserPunishment

Active squelches and blackouts.

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Primary key |
| `grid_hackr_id` | integer | FK to punished user |
| `punishment_type` | string | `squelch`, `blackout` |
| `expires_at` | datetime | When punishment lifts (null = permanent) |
| `created_at` | datetime | — |

---

## WebSocket Architecture

### LiveChatChannel

ActionCable channel for real-time packet delivery.

```ruby
# Subscription
{ channel: "LiveChatChannel", channel_slug: "ambient" }
{ channel: "LiveChatChannel", channel_slug: "live" }

# Broadcasts
ActionCable.server.broadcast("uplink:ambient", { type: "packet", data: {...} })
ActionCable.server.broadcast("uplink:live", { type: "packet", data: {...} })

# Events
{ type: "packet", data: { id, hackr_alias, content, created_at } }
{ type: "packet_dropped", data: { id } }
{ type: "presence", data: { count } }
{ type: "squelched", data: { until } }
```

### StreamStatusChannel

Broadcasts when stream goes live or ends.

```ruby
# Subscription
{ channel: "StreamStatusChannel" }

# Events
{ type: "stream_live", data: { stream_id, title } }
{ type: "stream_ended", data: { stream_id } }
```

---

## Frontend Components

### Component Structure

```
/app/javascript/components/
  uplink/
    UplinkPanel.tsx          # Main container, handles channel switching
    ChannelTabs.tsx          # #ambient | #live tab bar
    PacketList.tsx           # Scrollable packet display
    Packet.tsx               # Individual packet with @mention highlighting
    PacketInput.tsx          # Composer with char count and slow mode timer
    PresenceIndicator.tsx    # "X operatives connected"
    ReconnectingBanner.tsx   # Connection status overlay

/app/javascript/hooks/
  useUplink.ts               # ActionCable subscription hook
  useStreamStatus.ts         # Stream live/ended detection
```

### UplinkPanel

Main container component. Placement varies by context:

| Context | Placement |
|---------|-----------|
| Dedicated `/uplink` page | Full page with channel tabs |
| Homepage (stream live) | Side panel next to livestream embed |

### PacketInput

Message composer with:

- 512 character limit
- Remaining character count displayed as user types
- Plain text only (no markdown/formatting)
- Countdown timer when slow mode is active
- Disabled state when disconnected or squelched

---

## UX Behavior

### #live Activation

When a stream goes live while user is on site:

1. `StreamStatusChannel` broadcasts `stream_live` event
2. Slide-in banner appears from left, under top menu (same placement as alpha-mode banner)
3. #live tab becomes available in Uplink
4. If on homepage, #live panel appears next to stream

### #live Deactivation

When stream ends:

1. `StreamStatusChannel` broadcasts `stream_ended` event
2. #live lingers for 15 minutes with "Stream ended" indicator
3. After 15 minutes, #live closes and packets are archived
4. Users are moved to #ambient if they were in #live

### Joining a Channel

1. WebSocket subscription established
2. Server sends last 20 packets as initial payload
3. Presence count displayed: "X operatives connected"
4. Real-time packets stream in

### Packet History

| Channel | Behavior |
|---------|----------|
| **#ambient** | Persistent, loads last 20 on join |
| **#live** | Fresh each stream, archived after stream ends |

### @Mentions

- Packets containing `@youralias` are highlighted
- No sound notifications
- No push/external notifications

### Presence

- Count only: "47 operatives connected"
- No join/leave messages
- No user list

### Connection States

| State | UI |
|-------|-----|
| **Connected** | Normal operation |
| **Reconnecting** | "Reconnecting..." overlay, input disabled |
| **Disconnected** | Input blocked until connection restored |

### Outside Uplink

- Subtly pulsing indicator in navigation when #live is active
- No badge counts
- No notifications for new packets

---

## Admin UI

Located at `/root/uplink` (extends existing admin section).

### Channel Configuration

| Setting | Description |
|---------|-------------|
| **Name** | Display name for channel |
| **Description** | Channel description |
| **Enabled** | Toggle channel on/off |
| **Requires Livestream** | Only active when stream is live |
| **Slow Mode** | Seconds between packets (0 = disabled) |
| **Minimum Role** | Who can send packets (operative, operator, admin) |

### User Management

- View user's packet history
- Promote operative to operator
- Issue squelch (with duration selector and reason)
- Issue blackout (with optional duration and reason)
- View active punishments

### Moderation Log

Filterable, searchable list of all moderation actions:

| Column | Description |
|--------|-------------|
| **Timestamp** | When action occurred |
| **Actor** | Who performed the action |
| **Action** | warning, drop, squelch, blackout |
| **Target** | Affected user |
| **Reason** | Moderator-provided reason |
| **Duration** | For time-limited punishments |

### Quick Moderation

From packet view, operators/admins can:

- Drop packet (with reason)
- Squelch user (duration + reason)
- Blackout user (duration + reason) — admin only

---

## API Endpoints

### REST

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/uplink/channels` | List available channels |
| `GET` | `/api/uplink/channels/:slug` | Channel details + config |
| `GET` | `/api/uplink/channels/:slug/packets` | Recent packets (paginated) |
| `POST` | `/api/uplink/channels/:slug/packets` | Send a packet |
| `DELETE` | `/api/uplink/packets/:id` | Drop a packet (operator+) |
| `POST` | `/api/uplink/users/:id/squelch` | Squelch user (operator+) |
| `POST` | `/api/uplink/users/:id/blackout` | Blackout user (admin) |
| `DELETE` | `/api/uplink/users/:id/punishment` | Lift punishment |
| `GET` | `/api/uplink/moderation_log` | View log (operator+) |

### WebSocket

See [WebSocket Architecture](#websocket-architecture) section.

---

## Security Considerations

- Anonymous users cannot access Uplink (no visibility, no API access)
- Packets validated for length (512 char max) and profanity
- Rate limiting enforced server-side (slow mode)
- Squelch/blackout checked before accepting packets
- Operator actions logged in moderation log
- WebSocket connections authenticated via session cookie

---

## Future Considerations

Not in initial scope, but may be added later:

- Custom emotes/reactions
- Highlighted/pinned packets (admin feature)
- Viewer count broadcast
- @mention notifications outside Uplink
- User-configurable sound toggle
- Additional channels beyond #ambient and #live
- Packet formatting (markdown, links)
- Integration with PulseWire (crosspost packets as pulses)
- New packet indicator when scrolled up

---

## File Structure (Proposed)

```
# Backend
app/channels/live_chat_channel.rb
app/channels/stream_status_channel.rb
app/models/chat_channel.rb
app/models/chat_message.rb
app/models/moderation_log.rb
app/models/user_punishment.rb
app/controllers/api/uplink_controller.rb
app/controllers/api/uplink/packets_controller.rb
app/controllers/api/uplink/moderation_controller.rb
app/controllers/admin/uplink_controller.rb

# Frontend
app/javascript/components/uplink/UplinkPanel.tsx
app/javascript/components/uplink/ChannelTabs.tsx
app/javascript/components/uplink/PacketList.tsx
app/javascript/components/uplink/Packet.tsx
app/javascript/components/uplink/PacketInput.tsx
app/javascript/components/uplink/PresenceIndicator.tsx
app/javascript/components/uplink/ReconnectingBanner.tsx
app/javascript/hooks/useUplink.ts
app/javascript/hooks/useStreamStatus.ts

# Database
db/migrate/XXXXXX_create_chat_channels.rb
db/migrate/XXXXXX_create_chat_messages.rb
db/migrate/XXXXXX_create_moderation_logs.rb
db/migrate/XXXXXX_create_user_punishments.rb
db/migrate/XXXXXX_add_operator_role.rb
```

---

## References

- Existing ActionCable patterns: `app/channels/grid_channel.rb`, `app/channels/pulse_wire_channel.rb`
- Existing WebSocket hooks: `app/javascript/hooks/useActionCable.ts`, `app/javascript/hooks/usePulseWire.ts`
- Profanity filtering: `app/models/concerns/profanity_filterable.rb`
- User authentication: `app/models/grid_hackr.rb`
- Admin patterns: `app/controllers/admin/`
