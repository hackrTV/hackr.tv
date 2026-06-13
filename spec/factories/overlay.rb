FactoryBot.define do
  factory :overlay_scene_group do
    sequence(:name) { |n| "Group #{n}" }
    sequence(:slug) { |n| "group-#{n}" }
  end

  factory :overlay_scene_group_scene do
    overlay_scene_group
    overlay_scene
    sequence(:position) { |n| n }
  end
end
