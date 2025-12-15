#!/usr/bin/env ruby
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

# Read password from stdin (PAM sends it this way)
password = $stdin.gets&.chomp

# Validate
if Terminal::Password.valid?(password)
  exit 0  # PAM_SUCCESS
else
  # Log failed attempt (optional, for monitoring)
  File.open("/rails/log/ssh_auth.log", "a") do |f|
    f.puts "[#{Time.now.utc.iso8601}] Failed SSH auth attempt for user: #{ENV['PAM_USER']}"
  end rescue nil
  exit 1  # PAM_AUTH_ERR
end
