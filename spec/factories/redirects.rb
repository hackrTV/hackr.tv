FactoryBot.define do
  factory :redirect do
    sequence(:path) { |n| "/path-#{n}" }
    destination_url { "https://example.com" }
    domain { nil }

    trait :domain_specific do
      domain { "example.com" }
    end

    trait :ashlinn do
      domain { "ashlinn.net" }
      path { "/" }
      destination_url { "https://youtube.com/AshlinnSnow" }
    end

    trait :xeraen do
      domain { "xeraen.com" }
      path { "/" }
      destination_url { "/xeraen" }
    end
  end
end
