# == Schema Information
#
# Table name: playlist_tracks
# Database name: primary
#
#  id          :integer          not null, primary key
#  position    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  playlist_id :integer          not null
#  track_id    :integer          not null
#
# Indexes
#
#  index_playlist_tracks_on_playlist_id               (playlist_id)
#  index_playlist_tracks_on_playlist_id_and_position  (playlist_id,position)
#  index_playlist_tracks_on_playlist_id_and_track_id  (playlist_id,track_id) UNIQUE
#  index_playlist_tracks_on_track_id                  (track_id)
#
# Foreign Keys
#
#  playlist_id  (playlist_id => playlists.id)
#  track_id     (track_id => tracks.id)
#
require "rails_helper"

RSpec.describe PlaylistTrack, type: :model do
  describe "associations" do
    it "belongs to playlist" do
      playlist_track = create(:playlist_track)
      expect(playlist_track.playlist).to be_present
      expect(playlist_track.playlist).to be_a(Playlist)
    end

    it "belongs to track" do
      playlist_track = create(:playlist_track)
      expect(playlist_track.track).to be_present
      expect(playlist_track.track).to be_a(Track)
    end
  end

  describe "validations" do
    it "validates presence of position after creation" do
      playlist_track = create(:playlist_track)
      expect(playlist_track.position).to be_present
    end

    it "validates position is an integer greater than 0" do
      playlist = create(:playlist)
      artist = create(:artist)
      track = create(:track, artist: artist)

      pt = build(:playlist_track, playlist: playlist, track: track, position: 0)
      expect(pt).not_to be_valid
      expect(pt.errors[:position]).to include("must be greater than 0")

      pt.position = -1
      expect(pt).not_to be_valid

      pt.position = 1.5
      expect(pt).not_to be_valid
      expect(pt.errors[:position]).to include("must be an integer")

      pt.position = 1
      expect(pt).to be_valid
    end

    it "validates uniqueness of track_id scoped to playlist_id" do
      playlist = create(:playlist)
      artist = create(:artist)
      track = create(:track, artist: artist)

      create(:playlist_track, playlist: playlist, track: track)
      duplicate = build(:playlist_track, playlist: playlist, track: track)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:track_id]).to include("is already in this playlist")
    end

    it "allows same track in different playlists" do
      hackr = create(:grid_hackr)
      playlist1 = create(:playlist, grid_hackr: hackr)
      playlist2 = create(:playlist, grid_hackr: hackr)
      artist = create(:artist)
      track = create(:track, artist: artist)

      create(:playlist_track, playlist: playlist1, track: track)
      pt2 = build(:playlist_track, playlist: playlist2, track: track)

      expect(pt2).to be_valid
    end
  end

  describe "callbacks" do
    it "auto-assigns position as next available number" do
      playlist = create(:playlist)
      artist = create(:artist)
      track1 = create(:track, artist: artist)
      track2 = create(:track, artist: artist)
      track3 = create(:track, artist: artist)

      pt1 = create(:playlist_track, playlist: playlist, track: track1, position: nil)
      expect(pt1.position).to eq(1)

      pt2 = create(:playlist_track, playlist: playlist, track: track2, position: nil)
      expect(pt2.position).to eq(2)

      pt3 = create(:playlist_track, playlist: playlist, track: track3, position: nil)
      expect(pt3.position).to eq(3)
    end

    it "respects manually set position" do
      playlist = create(:playlist)
      artist = create(:artist)
      track = create(:track, artist: artist)

      pt = create(:playlist_track, playlist: playlist, track: track, position: 10)
      expect(pt.position).to eq(10)
    end
  end
end
