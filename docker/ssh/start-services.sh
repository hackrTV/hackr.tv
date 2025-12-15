#!/bin/bash
# Start both Rails server and SSH daemon for hackr.tv terminal access
#
# This script is used as the Docker entrypoint when terminal SSH access is enabled.

set -e

# Enable jemalloc for reduced memory usage
if [ -z "${LD_PRELOAD+x}" ]; then
    LD_PRELOAD=$(find /usr/lib -name libjemalloc.so.2 -print -quit)
    export LD_PRELOAD
fi

# Create necessary directories
mkdir -p /rails/log /rails/tmp/pids /var/run/sshd

# Ensure the access user exists
if ! id "access" &>/dev/null; then
    echo "Creating 'access' user for SSH terminal..."
    useradd -r -s /rails/bin/hackr-shell -d /nonexistent access
fi

# Generate SSH host keys if they don't exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "Generating SSH host keys..."
    ssh-keygen -A
fi

# Set up PAM configuration
if [ ! -f /etc/pam.d/sshd.hackr ]; then
    cp /rails/docker/ssh/pam-hackr-ssh /etc/pam.d/sshd
fi

# Set permissions
chmod 755 /rails/bin/hackr-shell
chmod 755 /rails/docker/ssh/validate-password.rb

# Prepare the database
echo "Preparing database..."
./bin/rails db:prepare

# Start SSH daemon in background
echo "Starting SSH daemon on port 9915..."
/usr/sbin/sshd -D -f /rails/docker/ssh/sshd_config &
SSHD_PID=$!

# Trap signals to gracefully shut down both services
cleanup() {
    echo "Shutting down services..."
    kill $SSHD_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# Start Rails server in foreground
echo "Starting Rails server on port 3000..."
exec ./bin/rails server -b 0.0.0.0 -p 3000
