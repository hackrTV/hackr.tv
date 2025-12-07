require "rails_helper"

RSpec.describe Api::SettingsController, type: :controller do
  describe "GET #index" do
    it "returns app settings as JSON" do
      get :index, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("prerelease_mode")
      expect(json).to have_key("prerelease_banner_text")
    end

    it "returns prerelease_mode from APP_SETTINGS" do
      get :index, format: :json

      json = JSON.parse(response.body)
      expect(json["prerelease_mode"]).to eq(APP_SETTINGS[:prerelease_mode])
    end

    it "returns prerelease_banner_text from APP_SETTINGS" do
      get :index, format: :json

      json = JSON.parse(response.body)
      expect(json["prerelease_banner_text"]).to eq(APP_SETTINGS[:prerelease_banner_text])
    end

    it "does not require authentication" do
      # No session setup - should still work
      get :index, format: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
