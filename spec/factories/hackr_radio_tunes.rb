# == Schema Information
#
# Table name: hackr_radio_tunes
# Database name: primary
#
#  id               :integer          not null, primary key
#  tuned_at         :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  grid_hackr_id    :integer          not null
#  radio_station_id :integer          not null
#
# Indexes
#
#  index_hackr_radio_tunes_on_grid_hackr_id     (grid_hackr_id)
#  index_hackr_radio_tunes_on_radio_station_id  (radio_station_id)
#  index_hackr_radio_tunes_unique               (grid_hackr_id,radio_station_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id     (grid_hackr_id => grid_hackrs.id)
#  radio_station_id  (radio_station_id => radio_stations.id)
#
FactoryBot.define do
  factory :hackr_radio_tune do
    association :grid_hackr
    association :radio_station
    tuned_at { Time.current }
  end
end
