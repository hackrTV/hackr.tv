# Terminal SSH Access System

BBS-style terminal interface providing SSH access to THE.CYBERPUL.SE universe.

```bash
ssh access@hackr.tv -p 9915
```

**Status:** Complete ✅
**Implemented:** 2025-12-15

---

## Overview

- **Port 9915** - Reference to Fracture Day (9/9/2115)
- **Daily rotating password** - Displayed at `/terminal` page
- **Anonymous browsing** - Codex, bands, tracks, read-only Wire
- **GridHackr auth** - Required for Grid access and posting
- **Real-time updates** - Live Wire and Grid notifications via Action Cable

---

## Implementation Summary

### Phase 1: Foundation ✅ COMPLETE

#### Core Library Files Created

| File | Purpose | Status |
|------|---------|--------|
| `lib/terminal.rb` | Main loader, requires all modules | ✅ |
| `lib/terminal/ansi.rb` | ANSI escape codes, 24-bit colors, box drawing chars | ✅ |
| `lib/terminal/renderer.rb` | HTML-to-ANSI converter, text formatting, box drawing | ✅ |
| `lib/terminal/password.rb` | Daily rotating password generator | ✅ |
| `lib/terminal/session.rb` | State machine, input loop, handler dispatch | ✅ |

#### Handler Files Created

| File | Purpose | Status |
|------|---------|--------|
| `lib/terminal/handlers/base_handler.rb` | Common utilities, IO helpers | ✅ |
| `lib/terminal/handlers/menu_handler.rb` | Main menu with numbered navigation | ✅ |
| `lib/terminal/handlers/grid_handler.rb` | THE PULSE GRID MUD (reuses CommandParser) | ✅ |
| `lib/terminal/handlers/wire_handler.rb` | PulseWire feed (read/post/echo/splice) | ✅ |
| `lib/terminal/handlers/codex_handler.rb` | Codex wiki browser | ✅ |
| `lib/terminal/handlers/bands_handler.rb` | hackr.fm band profiles | ✅ |
| `lib/terminal/handlers/vault_handler.rb` | Pulse Vault track listings | ✅ |
| `lib/terminal/handlers/login_handler.rb` | GridHackr authentication | ✅ |
| `lib/terminal/handlers/register_handler.rb` | New user registration | ✅ |

#### Web & Shell Files Created

| File | Purpose | Status |
|------|---------|--------|
| `bin/hackr-shell` | Executable restricted shell for SSH | ✅ |
| `app/controllers/terminal_controller.rb` | Credentials page controller | ✅ |
| `app/views/terminal/index.html.erb` | Cyberpunk credentials page with countdown | ✅ |
| `config/routes.rb` | Added `GET /terminal` route | ✅ |

#### Key Features Implemented

- **HTML-to-ANSI Conversion**: Converts Grid::CommandParser HTML output to terminal colors
- **24-bit Color Support**: Full RGB colors matching the web interface
- **Session State Machine**: Handles navigation between all subsystems
- **Global Commands**: `/menu`, `/grid`, `/wire`, `/codex`, `/bands`, `/vault`, `back`
- **Stack-based Navigation**: `back` command returns to previous screen
- **Anonymous Browsing**: Codex, bands, tracks, read-only Wire accessible without login
- **Authentication**: Login/register for Grid access and posting
- **Password Rotation**: Daily passwords with countdown timer on web page

#### Tests

- 198 terminal-specific specs in `spec/lib/terminal/`
- Module loads correctly in Rails environment

---

### Phase 2: ASCII Art System ✅ COMPLETE

**Goal:** Create rich ASCII art banners and visual effects for the cyberpunk aesthetic.

#### Art System Files Created

| File | Purpose | Status |
|------|---------|--------|
| `lib/terminal/art.rb` | Art loader with file caching | ✅ |
| `lib/terminal/effects.rb` | Visual effects (glitch, typing, scanline, etc.) | ✅ |

#### ASCII Art Banners Created (`lib/terminal/art/banners/`)

| File | Purpose | Status |
|------|---------|--------|
| `connection.txt` | Main hackr.tv connection banner | ✅ |
| `menu.txt` | Main menu header | ✅ |
| `grid.txt` | THE PULSE GRID section banner | ✅ |
| `wire.txt` | PulseWire section banner | ✅ |
| `codex.txt` | The Codex section banner | ✅ |
| `bands.txt` | hackr.fm section banner | ✅ |
| `vault.txt` | Pulse Vault section banner | ✅ |
| `login.txt` | Authentication banner | ✅ |
| `register.txt` | New user registration banner | ✅ |
| `welcome.txt` | Welcome to the Grid success banner | ✅ |
| `access_granted.txt` | Login success banner | ✅ |
| `access_denied.txt` | Login/registration failure banner | ✅ |

#### Effects Module Features

- `glitch_text(text, intensity:)` - Random character replacement with cyberpunk symbols
- `typing_effect(io, text, delay:, color:)` - Character-by-character output
- `scanline_effect(io, text, delay:, color:)` - Line-by-line reveal
- `flicker_banner(io, banner, flickers:, delay:)` - Connection animation
- `decrypt_effect(io, text, iterations:, delay:, color:)` - Decryption animation
- `gradient_text(text, start_color, end_color)` - Color gradient across text
- `boxed(text, title:, width:, color:)` - Box drawing around content

#### Handlers Updated

All handlers now use `Art.banner(:name)` instead of inline ASCII art:
- `menu_handler.rb` → `:menu`
- `grid_handler.rb` → `:grid`
- `wire_handler.rb` → `:wire`
- `codex_handler.rb` → `:codex`
- `bands_handler.rb` → `:bands`
- `vault_handler.rb` → `:vault`
- `login_handler.rb` → `:login`, `:access_granted`, `:access_denied`
- `register_handler.rb` → `:register`, `:welcome`, `:access_denied`
- `session.rb` → `:connection`

---

### Phase 4: Real-Time System ✅ COMPLETE

**Goal:** Enable live updates for Wire and Grid.

#### Implementation Approach

Implemented **direct Action Cable pubsub subscription** that:
- Subscribes directly to the same streams used by web clients
- Instant message delivery (no polling delay)
- Works across all environments (development async, production solid_cable)
- No additional gems required
- Bypasses WebSocket authentication since we're in the same Rails process

#### Files Created

| File | Purpose | Status |
|------|---------|--------|
| `lib/terminal/realtime_subscriber.rb` | Direct pubsub subscriber with callbacks | ✅ |

#### Features Implemented

**RealtimeSubscriber:**
- `on_wire(&block)` - Subscribe to `pulse_wire` stream, register callback
- `on_grid(&block)` - Register callback for room events
- `monitor_room(room_id)` - Subscribe to room's stream (using `GridChannel.broadcasting_for`)
- `stop` / `clear_callbacks` - Unsubscribe and clean up
- Automatically excludes own messages from notifications
- Instant delivery via `ActionCable.server.pubsub.subscribe`

**Wire Handler Integration:**
- Registers callback on enter, clears on leave
- Displays `═══ NEW PULSE ═══` notifications for new pulses
- Shows hackr alias and truncated content

**Grid Handler Integration:**
- Registers callback on enter, clears on leave
- Updates monitored room subscription on player movement
- Displays real-time events:
  - `@alias says: "message"` - Chat messages
  - `@alias arrives from the south.` - Player arrivals
  - `@alias leaves to the north.` - Player departures
  - `@alias picks up item.` / `@alias drops item.` - Item actions

**Session Integration:**
- Session owns the RealtimeSubscriber instance
- Calls `on_leave` when transitioning states
- Stops subscriber on disconnect/cleanup

---

### Phase 5: Testing ✅ COMPLETE

**Goal:** Comprehensive test coverage for terminal components.

#### Spec Files Created

| File | Purpose | Examples |
|------|---------|----------|
| `spec/lib/terminal/realtime_subscriber_spec.rb` | RealtimeSubscriber pubsub tests | 17 |
| `spec/lib/terminal/handlers/grid_handler_spec.rb` | GridHandler broadcast & realtime tests | 19 |
| `spec/lib/terminal/handlers/wire_handler_spec.rb` | WireHandler realtime tests | 8 |
| `spec/lib/terminal/renderer_spec.rb` | Renderer HTML-to-ANSI & color schemes | 41 |
| `spec/lib/terminal/password_spec.rb` | Daily password rotation | 24 |
| `spec/lib/terminal/session_spec.rb` | Session state machine & commands | 47 |
| `spec/lib/terminal/handlers/codex_handler_spec.rb` | CodexHandler browsing & display | 42 |

#### Test Coverage (198 terminal examples)

**Renderer (41 examples):**
- HTML-to-ANSI conversion with color styles
- Color scheme switching (default, amber, green, cga)
- Bold, dim, and combined formatting
- Box drawing, headers, dividers
- Menu items and key-value pairs
- Time ago formatting

**Password (24 examples):**
- Deterministic generation (same date = same password)
- Daily rotation (different dates = different passwords)
- Validation (case-insensitive, whitespace-tolerant)
- Countdown formatting
- Word list integrity

**Session (47 examples):**
- State transitions and stack-based navigation
- Handler creation and caching
- Authentication flow
- Global commands (/menu, /grid, /wire, etc.)
- Color scheme commands
- Easter egg command handling

**CodexHandler (42 examples):**
- Category listing and type filtering
- Search functionality
- Entry display with metadata
- Wiki link conversion
- Markdown header conversion
- Entry type color coding

---

### Phase 6: Deployment ✅ COMPLETE

**Goal:** Production SSH configuration and deployment.

#### Files Created

| File | Purpose | Status |
|------|---------|--------|
| `bin/terminal-test` | Local testing without SSH | ✅ |
| `bin/docker-start` | Smart Docker entrypoint (SSH toggle) | ✅ |
| `docker/ssh/sshd_config` | SSH daemon configuration | ✅ |
| `docker/ssh/pam-hackr-ssh` | PAM configuration for password validation | ✅ |
| `docker/ssh/validate-password.rb` | Daily password validation script | ✅ |
| `docker/ssh/start-services.sh` | Multi-service startup (legacy) | ✅ |
| `docs/TERMINAL_DEPLOYMENT.md` | Comprehensive deployment guide | ✅ |

#### Docker Configuration

- **Dockerfile** updated with OpenSSH server and PAM modules
- **docker-compose.yml** exposes port 9915, adds SSH key volume
- **TERMINAL_SSH_ENABLED** environment variable toggles SSH mode
- SSH host keys persisted via Docker volume

#### Local Testing

```bash
# Quick test (no SSH)
./bin/terminal-test

# Get today's password
rails runner "puts Terminal::Password.daily_password"
```

#### Docker Deployment

```bash
# Enable SSH terminal
echo "TERMINAL_SSH_ENABLED=true" >> .env

# Rebuild and deploy
docker compose build hackr_tv
docker compose up -d

# Test connection
ssh access@hackr.tv -p 9915
```

#### Key Features

- **Automatic SSH mode detection**: docker-start script checks TERMINAL_SSH_ENABLED
- **PAM password validation**: Uses Terminal::Password.valid? for daily rotating password
- **Host key persistence**: SSH keys stored in Docker volume for consistency
- **Dual-mode operation**: Same container runs web-only or web+SSH
- **Modern crypto**: Secure cipher suites (chacha20, aes256-gcm)
- **Security hardening**: No forwarding, restricted user, forced command

---

### Phase 7: Easter Eggs & Polish ✅ COMPLETE

**Goal:** Hidden features and immersive details.

#### Files Created

| File | Purpose | Status |
|------|---------|--------|
| `lib/terminal/easter_eggs.rb` | Easter egg command handler | ✅ |

#### Features Implemented

**Hidden Hacker Commands:**
- `hack` → Fake hacking animation with humorous denial
- `root` → Permission denied with incident reporting
- `sudo` / `sudo su` → Fake password prompt, always fails
- `su` → Authentication failure message

**Matrix Easter Egg:**
- `follow the white rabbit` → Matrix-style wake up sequence with rain effect

**Classic Adventure Game References:**
- `xyzzy` → Colossal Cave Adventure reference
- `plugh` → Another Adventure reference
- `42` → Hitchhiker's Guide reference
- `the cake is a lie` → Portal reference
- `help me obi-wan` → Star Wars reference

**System Command Spoofs:**
- `whoami` → Shows hackr identity or guest
- `uname -a` → Fake PulseOS system info
- `cat /etc/passwd` → Fake passwd file with GovCorp entries
- `rm -rf /` → Fake deletion (sandboxed joke)
- `ping govcorp` → Timeout with surveillance message
- `traceroute fracture.net` → Fake network trace
- `nmap localhost` → Fake port scan with in-universe services
- `metasploit` → Fake exploit framework

**Color Schemes:**
- `amber` → Classic amber phosphor CRT look
- `green` → Classic green phosphor CRT look
- `cga` → 4-color CGA palette (cyan, magenta, white, black)
- `default` / `cyberpunk` → Return to standard colors

**Glitch Command:**
- `//anything` → Glitch the text that follows with corruption effects

**GovCorp Intercepts:**
- 30% chance on connection to show random surveillance message
- 10 different intercept messages for variety

**Integration:**
- Color schemes persist across all terminal output
- Easter eggs work from any state (menu, grid, wire, etc.)
- Effects use existing `Terminal::Effects` module

#### Decision Log Update

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-12-15 | Easter eggs as separate module | Clean separation, easy to extend |
| 2025-12-15 | Color schemes via renderer | Affects all output consistently |

---

## Quick Reference

### Testing Terminal Locally

```bash
# Quick local test (recommended)
./bin/terminal-test

# Test module loading
bundle exec rails runner "require Rails.root.join('lib/terminal'); puts Terminal::Password.daily_password"

# Test interactive session (Ctrl+C to exit)
bundle exec rails runner "require Rails.root.join('lib/terminal'); Terminal.start"

# View credentials page
# Start server and visit http://localhost:3000/terminal
```

### Docker Deployment

```bash
# Enable SSH terminal
echo "TERMINAL_SSH_ENABLED=true" >> .env

# Build and deploy
docker compose build hackr_tv && docker compose up -d

# Test connection (password from /terminal page)
ssh access@hackr.tv -p 9915
```

### Daily Password

Generated by `lib/terminal/password.rb`. Rotates at midnight UTC.

```bash
rails runner "puts Terminal::Password.daily_password"
```

### Documentation

- **This file:** `docs/TERMINAL_PROGRESS.md` - Implementation reference
- **Deployment:** `docs/TERMINAL_DEPLOYMENT.md` - How to deploy locally and via Docker

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-12-15 | Use 24-bit ANSI colors | Match exact web colors for consistency |
| 2025-12-15 | Implement all handlers in Phase 1 | Get full system working early |
| 2025-12-15 | Defer ASCII art to Phase 2 | Core functionality first |
| 2025-12-15 | Defer real-time to Phase 4 | System works without it (polling fallback) |
| 2025-12-15 | Create 12 ASCII art banners | Rich cyberpunk aesthetic for every section |
| 2025-12-15 | External banner files vs inline | Easier editing, cleaner code |
| 2025-12-15 | Direct pubsub over WebSocket client | Same Rails process, no auth needed, instant delivery |
| 2025-12-15 | Single container for web+SSH | Simpler deployment, shared Action Cable pubsub |
| 2025-12-15 | PAM with Ruby validation script | Leverages existing password rotation logic |
| 2025-12-15 | TERMINAL_SSH_ENABLED toggle | Flexible deployment (web-only vs web+SSH) |
