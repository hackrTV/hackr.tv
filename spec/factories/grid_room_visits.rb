# == Schema Information
#
# Table name: grid_room_visits
# Database name: primary
#
#  id               :integer          not null, primary key
#  first_visited_at :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  grid_hackr_id    :integer          not null
#  grid_room_id     :integer          not null
#
# Indexes
#
#  index_grid_room_visits_on_grid_hackr_id  (grid_hackr_id)
#  index_grid_room_visits_on_grid_room_id   (grid_room_id)
#  index_grid_room_visits_unique            (grid_hackr_id,grid_room_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#  grid_room_id   (grid_room_id => grid_rooms.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :grid_room_visit do
    association :grid_hackr
    association :grid_room
    first_visited_at { Time.current }
  end
end
