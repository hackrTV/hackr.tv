# == Schema Information
#
# Table name: grid_hackrs
# Database name: primary
#
#  id               :integer          not null, primary key
#  api_token_digest :string
#  email            :string
#  hackr_alias      :string
#  last_activity_at :datetime
#  password_digest  :string
#  registration_ip  :string
#  role             :string
#  stats            :json
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  current_room_id  :integer
#
# Indexes
#
#  index_grid_hackrs_on_api_token_digest  (api_token_digest) UNIQUE
#  index_grid_hackrs_on_email             (email) UNIQUE
#  index_grid_hackrs_on_hackr_alias       (hackr_alias) UNIQUE
#  index_grid_hackrs_on_role              (role)
#
FactoryBot.define do
  factory :grid_hackr do
    sequence(:hackr_alias) { |n| "Hackr#{n}" }
    password { "hackthegrid" }
    role { "operative" }
    current_room { nil }

    trait :operator do
      role { "operator" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :online do
      association :current_room, factory: :grid_room
      last_activity_at { Time.current }
    end
  end
end
