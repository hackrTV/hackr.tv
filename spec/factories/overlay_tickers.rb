# == Schema Information
#
# Table name: overlay_tickers
# Database name: primary
#
#  id         :integer          not null, primary key
#  active     :boolean          default(TRUE)
#  content    :text             not null
#  direction  :string           default("left")
#  name       :string           not null
#  slug       :string           not null
#  speed      :integer          default(50)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_overlay_tickers_on_active  (active)
#  index_overlay_tickers_on_slug    (slug) UNIQUE
#
FactoryBot.define do
  factory :overlay_ticker do
    sequence(:name) { |n| "Ticker #{n}" }
    slug { "top" }
    content { "Breaking news: The Grid is online. Welcome to the future." }
    speed { 50 }
    direction { "left" }
    active { true }

    trait :bottom do
      slug { "bottom" }
    end

    trait :inactive do
      active { false }
    end

    trait :right_direction do
      direction { "right" }
    end
  end
end
