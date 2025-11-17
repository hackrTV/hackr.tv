FactoryBot.define do
  factory :radio_station_playlist do
    association :radio_station
    association :playlist
    # Let the callback assign position automatically (don't set it here)
  end
end
