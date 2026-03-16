# == Schema Information
#
# Table name: code_repositories
# Database name: primary
#
#  id               :integer          not null, primary key
#  default_branch   :string
#  description      :text
#  full_name        :string           not null
#  github_pushed_at :datetime
#  homepage         :string
#  language         :string
#  last_synced_at   :datetime
#  name             :string           not null
#  size_kb          :integer          default(0)
#  slug             :string           not null
#  stargazers_count :integer          default(0)
#  sync_error       :text
#  sync_status      :string
#  visible          :boolean          default(TRUE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  github_id        :integer          not null
#
# Indexes
#
#  index_code_repositories_on_github_id  (github_id) UNIQUE
#  index_code_repositories_on_slug       (slug) UNIQUE
#  index_code_repositories_on_visible    (visible)
#
FactoryBot.define do
  factory :code_repository do
    sequence(:name) { |n| "repo-#{n}" }
    sequence(:full_name) { |n| "hackrTV/repo-#{n}" }
    sequence(:slug) { |n| "repo-#{n}" }
    sequence(:github_id) { |n| 100_000 + n }
    description { "A test repository" }
    language { "Ruby" }
    default_branch { "main" }
    stargazers_count { 5 }
    size_kb { 1024 }
    github_pushed_at { 1.day.ago }
    last_synced_at { 1.hour.ago }
    sync_status { "synced" }
    visible { true }

    trait :unsynced do
      last_synced_at { nil }
      sync_status { nil }
    end

    trait :hidden do
      visible { false }
    end

    trait :errored do
      sync_status { "error" }
      sync_error { "git fetch failed" }
    end
  end
end
