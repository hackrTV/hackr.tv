# == Schema Information
#
# Table name: hackr_logs
# Database name: primary
#
#  id            :integer          not null, primary key
#  body          :text             not null
#  published     :boolean          default(FALSE), not null
#  published_at  :datetime
#  slug          :string           not null
#  timeline      :string           default("2120s"), not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_hackr_logs_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_logs_on_slug           (slug) UNIQUE
#  index_hackr_logs_on_timeline       (timeline)
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
FactoryBot.define do
  factory :hackr_log do
    title { "Resistance Update #{SecureRandom.hex(4)}" }
    slug { "resistance-update-#{SecureRandom.hex(4)}" }
    body { "This is a transmission from the resistance. The fight continues in 2125." }
    published { false }
    published_at { nil }
    association :grid_hackr

    trait :published do
      published { true }
      published_at { Time.current }
    end

    trait :with_markdown do
      body { "# Heading\n\n**Bold text** and *italic*\n\n- List item 1\n- List item 2" }
    end
  end
end
