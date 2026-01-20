FactoryBot.define do
  factory :chat_message do
    association :chat_channel
    association :grid_hackr
    sequence(:content) { |n| "Test message #{n}" }
    dropped { false }
    dropped_at { nil }

    trait :dropped do
      dropped { true }
      dropped_at { Time.current }
    end

    trait :with_stream do
      association :hackr_stream
    end
  end
end
