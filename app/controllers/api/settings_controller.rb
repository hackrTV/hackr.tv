module Api
  class SettingsController < ApplicationController
    # GET /api/settings
    # Returns public application settings for the frontend
    def index
      render json: {
        prerelease_mode: APP_SETTINGS[:prerelease_mode],
        prerelease_banner_text: APP_SETTINGS[:prerelease_banner_text]
      }
    end
  end
end
