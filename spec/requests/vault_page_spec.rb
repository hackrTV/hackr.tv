require "rails_helper"

# Phase 4: Hotwire Pulse Vault (replaces PulseVaultPage.tsx).
RSpec.describe "Vault page", type: :request do
  let(:artist) { create(:artist, name: "Test Artist", genre: "synthwave") }
  let(:release) { create(:release, artist: artist) }

  describe "GET /vault" do
    it "renders the track table with player row attributes" do
      track = create(:track, :with_audio, artist: artist, release: release, title: "Neon Drift")

      get "/vault"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("PULSE VAULT")
      expect(response.body).to include("Neon Drift")
      expect(response.body).to include("data-player-id=\"#{track.id}\"")
      expect(response.body).to include("data-player-url=")
      expect(response.body).to include("data-player-artist=\"Test Artist\"")
      expect(response.body).to include("data-search-text=")
      expect(response.body).to include('data-controller="track-list"')
    end

    it "excludes tracks hidden from the vault and coming-soon releases" do
      create(:track, :with_audio, artist: artist, release: release, title: "Visible One")
      create(:track, :with_audio, artist: artist, release: release, title: "Hidden One",
        show_in_pulse_vault: false)
      soon = create(:release, artist: artist, coming_soon: true)
      create(:track, :with_audio, artist: artist, release: soon, title: "Unreleased One")

      get "/vault"

      expect(response.body).to include("Visible One")
      expect(response.body).not_to include("Hidden One")
      expect(response.body).not_to include("Unreleased One")
    end

    it "pre-fills the filter input from the filter param" do
      create(:track, :with_audio, artist: artist, release: release)

      get "/vault", params: {filter: "neon"}

      expect(response.body).to include('value="neon"')
    end

    it "orders house artists ahead of others" do
      other = create(:artist, name: "AAA Newcomer")
      house = create(:artist, name: "XERAEN")
      create(:track, :with_audio, artist: other, release: create(:release, artist: other), title: "Newcomer Cut")
      create(:track, :with_audio, artist: house, release: create(:release, artist: house), title: "House Cut")

      get "/vault"

      expect(response.body.index("House Cut")).to be < response.body.index("Newcomer Cut")
    end
  end

  describe "GET /pulse-vault" do
    it "still redirects to /vault" do
      get "/pulse-vault"
      expect(response).to redirect_to("/vault")
    end
  end
end
