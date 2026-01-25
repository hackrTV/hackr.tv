# == Schema Information
#
# Table name: overlay_scenes
# Database name: primary
#
#  id         :integer          not null, primary key
#  active     :boolean          default(TRUE)
#  height     :integer          default(1080)
#  name       :string           not null
#  position   :integer          default(0)
#  scene_type :string           default("composition"), not null
#  settings   :json
#  slug       :string           not null
#  width      :integer          default(1920)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_overlay_scenes_on_active      (active)
#  index_overlay_scenes_on_scene_type  (scene_type)
#  index_overlay_scenes_on_slug        (slug) UNIQUE
#
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
