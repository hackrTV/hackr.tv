# == Schema Information
#
# Table name: overlay_tickers
# Database name: primary
#
#  id           :integer          not null, primary key
#  active       :boolean          default(TRUE)
#  content      :text             not null
#  content_type :string           default("static"), not null
#  direction    :string           default("left")
#  feed_source  :string
#  name         :string           not null
#  slug         :string           not null
#  speed        :integer          default(50)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_overlay_tickers_on_active  (active)
#  index_overlay_tickers_on_slug    (slug) UNIQUE
#
FactoryBot.define do
  factory :overlay_ticker do
    sequence(:name) { |n| "Ticker #{n}" }
    sequence(:slug) { |n| "ticker-#{n}" }
    content { "Breaking news: The Grid is online. Welcome to the future." }
    content_type { "static" }
    speed { 50 }
    direction { "left" }
    active { true }

    trait :dynamic do
      content_type { "dynamic" }
      feed_source { "api" }
      content { "Awaiting feed..." }
    end

    trait :inactive do
      active { false }
    end

    trait :right_direction do
      direction { "right" }
    end
  end
end
