# == Schema Information
#
# Table name: hackr_vod_watches
# Database name: primary
#
#  id              :integer          not null, primary key
#  watched_at      :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer          not null
#  hackr_stream_id :integer          not null
#
# Indexes
#
#  index_hackr_vod_watches_on_grid_hackr_id    (grid_hackr_id)
#  index_hackr_vod_watches_on_hackr_stream_id  (hackr_stream_id)
#  index_hackr_vod_watches_unique              (grid_hackr_id,hackr_stream_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#  hackr_stream_id  (hackr_stream_id => hackr_streams.id)
#
FactoryBot.define do
  factory :hackr_vod_watch do
    association :grid_hackr
    association :hackr_stream
    watched_at { Time.current }
  end
end
