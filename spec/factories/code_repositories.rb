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
