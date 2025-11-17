FactoryBot.define do
  factory :playlist_track do
    association :playlist
    association :track
    # position is auto-assigned by the model
  end
end
