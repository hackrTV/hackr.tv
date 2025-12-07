# frozen_string_literal: true

# Application-wide settings loaded from config/app_settings.yml
# Access via APP_SETTINGS[:key] anywhere in the application
#
# Example:
#   APP_SETTINGS[:prerelease_mode]  # => "alpha", "prerelease", or nil
#   APP_SETTINGS[:prerelease_banner_text]  # => String or nil

APP_SETTINGS = Rails.application.config_for(:app_settings).freeze
