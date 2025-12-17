#!/usr/local/bin/ruby
# frozen_string_literal: true

# PAM password validation script for hackr.tv terminal SSH access
#
# This script is called by pam_exec to validate the daily rotating password.
# It reads the password from stdin (as provided by PAM) and validates it
# against the Terminal::Password module.
#
# Exit codes:
#   0 = password valid (PAM_SUCCESS)
#   1 = password invalid (PAM_AUTH_ERR)

LOG_FILE = "/rails/log/ssh_auth.log"

def log(message)
  File.open(LOG_FILE, "a") { |f| f.puts "[#{Time.now.utc}] #{message}" }
rescue
  # Ignore logging errors
end

log "PAM script started, PAM_USER=#{ENV["PAM_USER"]}"

APP_ROOT = ENV.fetch("RAILS_ROOT", "/rails")

# Set up minimal environment
ENV["RAILS_ENV"] ||= "production"
ENV["BUNDLE_GEMFILE"] ||= File.join(APP_ROOT, "Gemfile")
ENV["BUNDLE_DEPLOYMENT"] ||= "1"
ENV["BUNDLE_PATH"] ||= "/usr/local/bundle"
ENV["BUNDLE_WITHOUT"] ||= "development"

# Only load what we need for password validation
# Don't load full Rails to keep it fast
Dir.chdir(APP_ROOT)

# Load bundler and minimal dependencies
require "bundler/setup"
require "date"

# Load just the password module
require_relative "#{APP_ROOT}/lib/terminal/password"

# Read password from stdin
# pam_exec with expose_authtok sends: password + null byte
# Try multiple read methods to handle different PAM behaviors
raw_input = $stdin.read
password = raw_input&.chomp("\0")&.chomp&.strip

log "Password received (length=#{password&.length}), expected=#{Terminal::Password.daily_password}"

# Validate
if Terminal::Password.valid?(password)
  log "AUTH SUCCESS for user: #{ENV["PAM_USER"]}"
  exit 0  # PAM_SUCCESS
else
  log "AUTH FAILED for user: #{ENV["PAM_USER"]}"
  exit 1  # PAM_AUTH_ERR
end
