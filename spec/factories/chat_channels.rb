# == Schema Information
#
# Table name: chat_channels
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  is_active           :boolean          default(TRUE), not null
#  minimum_role        :string           default("operative"), not null
#  name                :string           not null
#  requires_livestream :boolean          default(FALSE), not null
#  slow_mode_seconds   :integer          default(0), not null
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_chat_channels_on_is_active  (is_active)
#  index_chat_channels_on_slug       (slug) UNIQUE
#
FactoryBot.define do
  factory :chat_channel do
    sequence(:slug) { |n| "channel#{n}" }
    sequence(:name) { |n| "#channel#{n}" }
    description { "A test chat channel" }
    is_active { true }
    requires_livestream { false }
    slow_mode_seconds { 0 }
    minimum_role { "operative" }

    trait :inactive do
      is_active { false }
    end

    trait :livestream_only do
      requires_livestream { true }
    end

    trait :slow_mode do
      slow_mode_seconds { 30 }
    end

    trait :operator_only do
      minimum_role { "operator" }
    end

    trait :admin_only do
      minimum_role { "admin" }
    end
  end
end
