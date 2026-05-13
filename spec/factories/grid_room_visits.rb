FactoryBot.define do
  factory :grid_room_visit do
    association :grid_hackr
    association :grid_room
    first_visited_at { Time.current }
  end
end
