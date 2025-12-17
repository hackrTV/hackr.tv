# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t hackr_rails .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name hackr_rails hackr_rails

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages (including OpenSSH for terminal access)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 python3 python3-pip openssh-server libpam-modules && \
    pip3 install --no-cache-dir --break-system-packages litecli && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives && \
    mkdir -p /var/run/sshd

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and Node.js for Vite
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config nodejs npm && \
    npm install -g pnpm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Install JavaScript dependencies
RUN pnpm install --frozen-lockfile

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create users and set permissions
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    useradd -r -s /rails/bin/hackr-shell -d /nonexistent access && \
    chown -R rails:rails db log storage tmp && \
    chmod +x /rails/bin/hackr-shell /rails/bin/docker-start /rails/docker/ssh/validate-password.rb /rails/docker/ssh/start-services.sh && \
    cp /rails/docker/ssh/pam-hackr-ssh /etc/pam.d/sshd && \
    cp /rails/docker/ssh/sshd_config /etc/ssh/sshd_config.hackr

# Generate SSH host keys in /etc/ssh/keys/ (volume-mounted separately from config)
# This allows sshd_config updates on rebuild while persisting keys
RUN mkdir -p /etc/ssh/keys && \
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/keys/ssh_host_rsa_key -N "" && \
    ssh-keygen -t ecdsa -b 521 -f /etc/ssh/keys/ssh_host_ecdsa_key -N "" && \
    ssh-keygen -t ed25519 -f /etc/ssh/keys/ssh_host_ed25519_key -N ""

# Environment variable to enable/disable SSH terminal access
ENV TERMINAL_SSH_ENABLED="false"

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose both web and SSH ports
EXPOSE 3000 9915

# Smart start script handles both regular and SSH-enabled modes
# Set TERMINAL_SSH_ENABLED=true to enable SSH terminal on port 9915
CMD ["/rails/bin/docker-start"]
