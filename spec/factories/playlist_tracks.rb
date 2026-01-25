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
FactoryBot.define do
  factory :playlist_track do
    association :playlist
    association :track
    # position is auto-assigned by the model
  end
end
