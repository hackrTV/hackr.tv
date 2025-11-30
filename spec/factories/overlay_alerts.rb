FactoryBot.define do
  factory :overlay_alert do
    alert_type { "custom" }
    title { "Alert Title" }
    message { "Alert message content" }
    data { {} }
    displayed { false }
    displayed_at { nil }
    expires_at { nil }

    trait :displayed do
      displayed { true }
      displayed_at { Time.current }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :subscriber do
      alert_type { "subscriber" }
      title { "New Subscriber!" }
    end

    trait :donation do
      alert_type { "donation" }
      title { "Donation Received!" }
    end

    trait :raid do
      alert_type { "raid" }
      title { "Incoming Raid!" }
    end

    trait :follow do
      alert_type { "follow" }
      title { "New Follower!" }
    end
  end
end
