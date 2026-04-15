require "rails_helper"

# Regression: the `playlists_created` achievement check was previously
# fired on EVERY track add to any playlist. Since the checker's
# populated_playlist_count only changes on a 0→1 transition per
# playlist, we now gate the check to that transition to avoid useless
# per-add checker runs.
RSpec.describe Api::PlaylistTracksController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:playlist) { create(:playlist, grid_hackr: hackr) }
  let(:track_a) { create(:track) }
  let(:track_b) { create(:track) }
  let(:track_c) { create(:track) }

  before { session[:grid_hackr_id] = hackr.id }

  describe "achievement check gating on POST #create" do
    it "fires `playlists_created` exactly once on the playlist's first track" do
      expect_any_instance_of(Grid::AchievementChecker)
        .to receive(:check).with("playlists_created").once

      post :create, params: {playlist_id: playlist.id, track_id: track_a.id}, format: :json
      expect(response).to have_http_status(:created)
    end

    it "does NOT fire on the 2nd or 3rd track add — population count already counted this playlist" do
      post :create, params: {playlist_id: playlist.id, track_id: track_a.id}, format: :json

      expect_any_instance_of(Grid::AchievementChecker).not_to receive(:check)

      post :create, params: {playlist_id: playlist.id, track_id: track_b.id}, format: :json
      post :create, params: {playlist_id: playlist.id, track_id: track_c.id}, format: :json
      expect(response).to have_http_status(:created)
    end

    it "fires again when a DIFFERENT playlist receives its first track" do
      # First playlist's first track — should fire once
      post :create, params: {playlist_id: playlist.id, track_id: track_a.id}, format: :json

      second_playlist = create(:playlist, grid_hackr: hackr)

      expect_any_instance_of(Grid::AchievementChecker)
        .to receive(:check).with("playlists_created").once

      post :create, params: {playlist_id: second_playlist.id, track_id: track_b.id}, format: :json
    end
  end
end
