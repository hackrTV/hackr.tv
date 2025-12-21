require "rails_helper"

RSpec.describe ApplicationController, type: :request do
  describe "case-insensitive routing" do
    describe "redirect_to_lowercase_path" do
      it "redirects uppercase paths to lowercase with 301" do
        get "/FM/Radio"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/fm/radio")
      end

      it "redirects mixed case paths to lowercase" do
        get "/TheCyberPulse"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/thecyberpulse")
      end

      it "preserves query parameters when redirecting" do
        get "/FM/Pulse_Vault?search=test&page=2"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/fm/pulse_vault?search=test&page=2")
      end

      it "does not redirect already lowercase paths" do
        get "/fm/radio"
        expect(response).not_to have_http_status(:moved_permanently)
        expect(response).to have_http_status(:success)
      end

      it "does not redirect /shared/ paths (case-sensitive tokens)" do
        # Create a playlist with a token
        hackr = create(:grid_hackr)
        playlist = create(:playlist, grid_hackr: hackr, is_public: true)

        # Mix case in the path but keep token as-is
        get "/shared/#{playlist.share_token}"
        expect(response).not_to have_http_status(:moved_permanently)
      end

      it "redirects API paths to lowercase" do
        get "/API/Tracks"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/api/tracks")
      end

      it "does not redirect /api/shared_playlists/ paths" do
        hackr = create(:grid_hackr)
        playlist = create(:playlist, grid_hackr: hackr, is_public: true)

        get "/api/shared_playlists/#{playlist.share_token}", as: :json
        expect(response).not_to have_http_status(:moved_permanently)
      end

      it "redirects band profile paths to lowercase" do
        get "/System_Rot"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/system_rot")
      end

      it "redirects grid paths to lowercase" do
        get "/Grid/Login"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/grid/login")
      end

      it "redirects codex paths to lowercase" do
        get "/Codex"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/codex")
      end

      it "redirects wire paths to lowercase" do
        get "/Wire"
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/wire")
      end

      it "does not redirect /assets/ paths" do
        # Assets have fingerprinted names with mixed case
        get "/assets/Application-AbC123.js"
        expect(response).not_to have_http_status(:moved_permanently)
      end

      it "does not redirect files with asset extensions" do
        get "/some/Path/File.JS"
        expect(response).not_to have_http_status(:moved_permanently)
      end

      it "does not redirect image files" do
        get "/images/Logo.PNG"
        expect(response).not_to have_http_status(:moved_permanently)
      end

      it "does not redirect audio files" do
        get "/audio/Track.MP3"
        expect(response).not_to have_http_status(:moved_permanently)
      end
    end
  end
end
