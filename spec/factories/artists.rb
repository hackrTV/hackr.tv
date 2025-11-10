FactoryBot.define do
  factory :artist do
    name { "Test Artist" }
    sequence(:slug) { |n| "test-artist-#{n}" }
    genre { "Electronic" }

    trait :thecyberpulse do
      name { "The.CyberPul.se" }
      slug { "thecyberpulse" }
      genre { "Synthwave/Cyberpunk" }
    end

    trait :xeraen do
      name { "XERAEN" }
      slug { "xeraen" }
      genre { "Industrial/Dark Synth" }
    end
  end
end
