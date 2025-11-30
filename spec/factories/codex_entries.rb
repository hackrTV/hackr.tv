FactoryBot.define do
  factory :codex_entry do
    sequence(:name) { |n| "Entry #{n}" }
    sequence(:slug) { |n| "entry-#{n}" }
    entry_type { "person" }
    summary { "Entry summary text" }
    content { "Entry content text" }
    metadata { {} }
    published { false }
    position { 1 }

    trait :published do
      published { true }
    end

    trait :organization do
      entry_type { "organization" }
    end

    trait :event do
      entry_type { "event" }
    end

    trait :location do
      entry_type { "location" }
    end

    trait :technology do
      entry_type { "technology" }
    end

    trait :faction do
      entry_type { "faction" }
    end

    trait :item do
      entry_type { "item" }
    end
  end
end
