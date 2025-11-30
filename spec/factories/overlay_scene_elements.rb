FactoryBot.define do
  factory :overlay_scene_element do
    association :overlay_scene
    association :overlay_element
    x { 0 }
    y { 0 }
    width { 400 }
    height { 100 }
    z_index { 1 }
    overrides { {} }
  end
end
