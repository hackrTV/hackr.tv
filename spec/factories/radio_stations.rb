# == Schema Information
#
# Table name: radio_stations
# Database name: primary
#
#  id          :integer          not null, primary key
#  color       :string
#  description :text
#  genre       :string
#  hidden      :boolean          default(FALSE), not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  slug        :string           not null
#  stream_url  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_radio_stations_on_position  (position)
#  index_radio_stations_on_slug      (slug) UNIQUE
#
FactoryBot.define do
  factory :radio_station do
    sequence(:name) { |n| "Station #{n}" }
    sequence(:slug) { |n| "station-#{n}" }
    description { "A test radio station" }
    genre { "Electronic" }
    color { "purple-168" }
    stream_url { "http://example.com/stream" }
    position { 0 }
  end
end
