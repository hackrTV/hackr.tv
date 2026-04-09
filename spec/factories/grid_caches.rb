# == Schema Information
#
# Table name: grid_caches
# Database name: primary
#
#  id            :integer          not null, primary key
#  address       :string           not null
#  archived_at   :datetime
#  is_default    :boolean          default(FALSE), not null
#  nickname      :string
#  status        :string           default("active"), not null
#  system_type   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer
#
# Indexes
#
#  index_grid_caches_on_address         (address) UNIQUE
#  index_grid_caches_on_grid_hackr_id   (grid_hackr_id)
#  index_grid_caches_on_hackr_nickname  (grid_hackr_id,nickname) UNIQUE WHERE nickname IS NOT NULL
#  index_grid_caches_on_system_type     (system_type)
#
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
