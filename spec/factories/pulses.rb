# == Schema Information
#
# Table name: pulses
# Database name: primary
#
#  id                :integer          not null, primary key
#  content           :text             not null
#  echo_count        :integer          default(0), not null
#  is_seed           :boolean          default(FALSE), not null
#  pulsed_at         :datetime         not null
#  signal_dropped    :boolean          default(FALSE), not null
#  signal_dropped_at :datetime
#  splice_count      :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  grid_hackr_id     :integer          not null
#  parent_pulse_id   :integer
#  thread_root_id    :integer
#
# Indexes
#
#  index_pulses_on_grid_hackr_id    (grid_hackr_id)
#  index_pulses_on_is_seed          (is_seed)
#  index_pulses_on_parent_pulse_id  (parent_pulse_id)
#  index_pulses_on_pulsed_at        (pulsed_at)
#  index_pulses_on_signal_dropped   (signal_dropped)
#  index_pulses_on_thread_root_id   (thread_root_id)
#
# Foreign Keys
#
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#  parent_pulse_id  (parent_pulse_id => pulses.id)
#  thread_root_id   (thread_root_id => pulses.id)
#
FactoryBot.define do
  factory :pulse do
    association :grid_hackr
    sequence(:content) { |n| "Pulse transmission #{n} from THE WIRE network" }
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
