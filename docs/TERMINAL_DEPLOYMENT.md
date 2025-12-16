# Terminal SSH Access - Deployment Guide

This guide covers deploying the hackr.tv terminal SSH access system locally and via Docker.

## Overview

The terminal system provides a BBS-style SSH interface to THE.CYBERPUL.SE at `ssh access@hackr.tv -p 9915`. Features include:

- Daily rotating password (displayed at `/terminal` page)
- Rich ASCII art and cyberpunk aesthetics
- THE PULSE GRID MUD access
- PulseWire social network
- Codex lore wiki
- hackr.fm music catalog
- Easter eggs and color schemes

---

## Local Testing (Development)

### Quick Test (No SSH)

The fastest way to test the terminal locally without SSH setup:

```bash
# Run the terminal directly in your terminal
./bin/terminal-test

# Or via rails runner
bundle exec rails runner "require Rails.root.join('lib/terminal'); Terminal.start"
```

This runs the full terminal experience in your current shell. Press `Ctrl+C` to exit.

### Get Today's Password

```bash
bundle exec rails runner "puts Terminal::Password.daily_password"
```

---

## Local SSH Setup (Linux/macOS)

For testing the full SSH experience on your development machine:

### 1. Create the Access User

```bash
# Create system user with hackr-shell as the login shell
sudo useradd -r -s /full/path/to/hackr.tv/bin/hackr-shell access
```

### 2. Configure OpenSSH

Create `/etc/ssh/sshd_config.d/hackr.conf`:

```ssh-config
# hackr.tv Terminal SSH Configuration
Port 9915

Match User access
    ForceCommand /full/path/to/hackr.tv/bin/hackr-shell
    PasswordAuthentication yes
    PubkeyAuthentication no
    AllowTcpForwarding no
    X11Forwarding no
    PermitTTY yes
```

### 3. Set Up PAM Authentication

Create `/etc/pam.d/hackr-ssh`:

```pam
auth       required   pam_exec.so   expose_authtok  /full/path/to/hackr.tv/docker/ssh/validate-password.rb
auth       required   pam_permit.so
account    required   pam_permit.so
session    required   pam_permit.so
```

Then update the SSH config to use this PAM service:
```ssh-config
# In your sshd_config
UsePAM yes
```

### 4. Restart SSH and Test

```bash
sudo systemctl restart sshd

# Test connection (password is displayed at /terminal page)
ssh access@localhost -p 9915
```

---

## Docker Deployment

The Docker deployment runs both the Rails web server and SSH daemon in a single container.

### Configuration

In your `.env` file or docker-compose environment:

```env
# Enable SSH terminal access (set to "true" to enable)
TERMINAL_SSH_ENABLED=true

# Other required variables
SECRET_KEY_BASE=your-secret-key
DOMAIN=hackr.tv
```

### docker-compose.yml Configuration

The included `docker-compose.yml` already has SSH terminal support:

```yaml
services:
  hackr_tv:
    build:
      context: ./hackr.tv
      dockerfile: Dockerfile
    environment:
      - TERMINAL_SSH_ENABLED=${TERMINAL_SSH_ENABLED:-false}
      # ... other env vars
    volumes:
      - hackr_storage:/rails/storage
      - hackr_ssh_keys:/etc/ssh  # Persist SSH host keys
    ports:
      - "9915:9915"  # SSH terminal access
```

### Deploy Steps

1. **Set environment variable** to enable SSH:
   ```bash
   echo "TERMINAL_SSH_ENABLED=true" >> .env
   ```

2. **Rebuild the container**:
   ```bash
   docker compose build hackr_tv
   ```

3. **Start the services**:
   ```bash
   docker compose up -d
   ```

4. **Verify SSH is running**:
   ```bash
   docker compose logs hackr_tv | grep "SSH daemon"
   ```

5. **Test connection**:
   ```bash
   # Get today's password from the web interface
   curl https://hackr.tv/terminal

   # Connect via SSH
   ssh access@hackr.tv -p 9915
   ```

### Disabling SSH Terminal

To run without SSH (web-only mode):

```bash
# Set to false or remove the variable
TERMINAL_SSH_ENABLED=false docker compose up -d
```

---

## Production Considerations

### Firewall Rules

Ensure port 9915 is accessible:

```bash
# UFW (Ubuntu)
sudo ufw allow 9915/tcp

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-port=9915/tcp
sudo firewall-cmd --reload
```

### SSH Host Key Persistence

The `hackr_ssh_keys` volume persists SSH host keys across container restarts. This prevents SSH clients from seeing host key changes.

If you need to regenerate keys:
```bash
docker compose down
docker volume rm hackr_ssh_keys
docker compose up -d
```

### Monitoring & Logging

Failed authentication attempts are logged to `/rails/log/ssh_auth.log`:

```bash
docker compose exec hackr_tv tail -f /rails/log/ssh_auth.log
```

### Session Limits

The default configuration allows up to 10 concurrent SSH sessions. Adjust in `docker/ssh/sshd_config`:

```ssh-config
MaxSessions 10
```

### Security Hardening

The SSH configuration already includes:
- Modern cipher suites only
- Disabled TCP/agent/X11 forwarding
- Forced command restriction
- Connection timeouts

For additional hardening, consider:
- Rate limiting with fail2ban
- Network-level access control
- Regular log auditing

---

## Troubleshooting

### "Connection refused" on port 9915

1. Check if SSH daemon is running:
   ```bash
   docker compose exec hackr_tv ps aux | grep sshd
   ```

2. Check SSH is enabled:
   ```bash
   docker compose exec hackr_tv echo $TERMINAL_SSH_ENABLED
   ```

3. Check container logs:
   ```bash
   docker compose logs hackr_tv | grep -i ssh
   ```

### "Permission denied" password errors

1. Verify today's password:
   ```bash
   docker compose exec hackr_tv ./bin/rails runner "puts Terminal::Password.daily_password"
   ```

2. Check PAM is configured:
   ```bash
   docker compose exec hackr_tv cat /etc/pam.d/sshd
   ```

### Terminal shows garbled characters

Ensure your terminal supports:
- UTF-8 encoding
- 24-bit (true color) ANSI codes
- Unicode box drawing characters

Recommended terminals:
- iTerm2 (macOS)
- Windows Terminal
- GNOME Terminal
- Alacritty
- kitty

### Real-time updates not working

The terminal uses Action Cable pubsub for real-time features. Ensure:
1. The Rails server is running
2. Solid Cable is properly configured
3. The database is accessible

---

## File Structure

```
hackr.tv/
├── bin/
│   ├── hackr-shell           # SSH login shell
│   ├── terminal-test         # Local testing script
│   └── docker-start          # Docker entrypoint script
├── docker/
│   └── ssh/
│       ├── sshd_config       # SSH daemon configuration
│       ├── pam-hackr-ssh     # PAM configuration
│       ├── validate-password.rb  # Password validation script
│       └── start-services.sh # Legacy multi-service starter
├── lib/
│   └── terminal/             # Terminal Ruby modules
│       ├── session.rb        # Main session handler
│       ├── password.rb       # Daily password generation
│       ├── renderer.rb       # ANSI rendering
│       ├── handlers/         # Command handlers
│       └── ...
└── app/
    ├── controllers/
    │   └── terminal_controller.rb
    └── views/
        └── terminal/
            └── index.html.erb  # Credentials page
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Local test | `./bin/terminal-test` |
| Get password | `rails runner "puts Terminal::Password.daily_password"` |
| Enable SSH (Docker) | `TERMINAL_SSH_ENABLED=true` in `.env` |
| Connect | `ssh access@host -p 9915` |
| View logs | `docker compose logs hackr_tv` |
| Rebuild | `docker compose build hackr_tv` |

---

## See Also

- [TERMINAL_PROGRESS.md](./TERMINAL_PROGRESS.md) - Implementation progress tracker
- [TERMINAL_IMPLEMENTATION_PLAN.md](./TERMINAL_IMPLEMENTATION_PLAN.md) - Original design document
- [TELNET_TERMINAL_DESIGN.md](./TELNET_TERMINAL_DESIGN.md) - Initial design notes
