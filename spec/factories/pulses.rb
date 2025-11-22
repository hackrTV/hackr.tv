FactoryBot.define do
  factory :pulse do
    association :grid_hackr
    content { Faker::Lorem.sentence(word_count: 10) }
    # pulsed_at is auto-set by the model
    echo_count { 0 }
    splice_count { 0 }
    signal_dropped { false }
    signal_dropped_at { nil }
    parent_pulse { nil }
    thread_root { nil }

    trait :with_parent do
      association :parent_pulse, factory: :pulse
    end

    trait :signal_dropped do
      signal_dropped { true }
      signal_dropped_at { Time.current }
    end

    trait :with_echoes do
      after(:create) do |pulse|
        create_list(:echo, 3, pulse: pulse)
      end
    end

    trait :with_splices do
      after(:create) do |pulse|
        create_list(:pulse, 2, parent_pulse: pulse)
      end
    end
  end
end
