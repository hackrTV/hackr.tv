FactoryBot.define do
  factory :grid_cache do
    sequence(:address) { |n| "CACHE-#{format("%04X", n)}-#{format("%04X", n + 1000)}" }
    status { "active" }
    is_default { false }

    trait :default do
      is_default { true }
    end

    trait :abandoned do
      status { "abandoned" }
      archived_at { Time.current }
    end

    trait :mining_pool do
      address { "CACHE-MINE-POOL" }
      system_type { "mining_pool" }
    end

    trait :gameplay_pool do
      address { "CACHE-PLAY-POOL" }
      system_type { "gameplay_pool" }
    end

    trait :burn do
      address { "CACHE-BURN-0000" }
      system_type { "burn" }
    end

    trait :redemption do
      address { "CACHE-REDM-0000" }
      system_type { "redemption" }
    end

    trait :genesis do
      address { "CACHE-GNSS-0000" }
      system_type { "genesis" }
    end
  end
end
