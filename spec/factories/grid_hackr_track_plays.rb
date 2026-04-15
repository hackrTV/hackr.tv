# == Schema Information
#
# Table name: grid_hackr_track_plays
# Database name: primary
#
#  id              :integer          not null, primary key
#  first_played_at :datetime         not null
#  play_count      :integer          default(1), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer          not null
#  track_id        :integer          not null
#
# Indexes
#
#  index_grid_hackr_track_plays_on_grid_hackr_id  (grid_hackr_id)
#  index_grid_hackr_track_plays_on_track_id       (track_id)
#  index_track_plays_unique                       (grid_hackr_id,track_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  track_id       (track_id => tracks.id)
#
FactoryBot.define do
  factory :grid_hackr_track_play do
    association :grid_hackr
    association :track
    first_played_at { Time.current }
    play_count { 1 }
  end
end
