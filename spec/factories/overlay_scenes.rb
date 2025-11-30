FactoryBot.define do
  factory :overlay_scene do
    sequence(:name) { |n| "Scene #{n}" }
    sequence(:slug) { |n| "scene-#{n}" }
    scene_type { "fullscreen" }
    width { 1920 }
    height { 1080 }
    active { true }
    position { 1 }
    settings { {} }

    trait :composition do
      scene_type { "composition" }
    end

    trait :inactive do
      active { false }
    end
  end
end
