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
