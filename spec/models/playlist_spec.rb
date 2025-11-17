require "rails_helper"

RSpec.describe Playlist, type: :model do
  describe "associations" do
    it { should belong_to(:grid_hackr) }
    it { should have_many(:playlist_tracks).dependent(:destroy) }
    it { should have_many(:tracks).through(:playlist_tracks) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }

    it "validates uniqueness of share_token" do
      hackr = create(:grid_hackr)
      playlist1 = create(:playlist, grid_hackr: hackr)
      playlist2 = build(:playlist, grid_hackr: hackr)
      # Manually set the same share_token after initialization (bypass callback)
      playlist2.share_token = playlist1.share_token

      expect(playlist2).not_to be_valid
      expect(playlist2.errors[:share_token]).to include("has already been taken")
    end
  end

  describe "callbacks" do
    it "generates share_token before validation on create" do
      hackr = create(:grid_hackr)
      playlist = build(:playlist, grid_hackr: hackr, share_token: nil)

      expect(playlist.share_token).to be_nil
      playlist.validate
      expect(playlist.share_token).to be_present
      expect(playlist.share_token.length).to be >= 16
    end

    it "does not regenerate share_token on update" do
      playlist = create(:playlist)
      original_token = playlist.share_token

      playlist.update(name: "Updated Name")
      expect(playlist.share_token).to eq(original_token)
    end
  end

  describe "default scope" do
    it "orders playlists by created_at descending" do
      hackr = create(:grid_hackr)
      playlist1 = create(:playlist, grid_hackr: hackr, created_at: 2.days.ago)
      playlist2 = create(:playlist, grid_hackr: hackr, created_at: 1.day.ago)
      playlist3 = create(:playlist, grid_hackr: hackr, created_at: Time.current)

      expect(hackr.playlists.to_a).to eq([playlist3, playlist2, playlist1])
    end
  end

  describe "#track_count" do
    it "returns the number of tracks in the playlist" do
      playlist = create(:playlist)
      artist = create(:artist)
      track1 = create(:track, artist: artist)
      track2 = create(:track, artist: artist)

      create(:playlist_track, playlist: playlist, track: track1)
      create(:playlist_track, playlist: playlist, track: track2)

      expect(playlist.track_count).to eq(2)
    end

    it "returns 0 for empty playlist" do
      playlist = create(:playlist)
      expect(playlist.track_count).to eq(0)
    end
  end
end
