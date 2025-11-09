FactoryBot.define do
  factory :hackr_log do
    title { "Resistance Update #{SecureRandom.hex(4)}" }
    slug { "resistance-update-#{SecureRandom.hex(4)}" }
    body { "This is a transmission from the resistance. The fight continues in 2125." }
    published { false }
    published_at { nil }
    association :author, factory: :grid_hackr

    trait :published do
      published { true }
      published_at { Time.current }
    end

    trait :with_markdown do
      body { "# Heading\n\n**Bold text** and *italic*\n\n- List item 1\n- List item 2" }
    end
  end
end
