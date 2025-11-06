FactoryBot.define do
  factory :artist do
    name { "Test Artist" }
    sequence(:slug) { |n| "test-artist-#{n}" }

    trait :thecyberpulse do
      name { "The.CyberPul.se" }
      slug { "thecyberpulse" }
    end

    trait :xeraen do
      name { "XERAEN" }
      slug { "xeraen" }
    end
  end
end
