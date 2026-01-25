# == Schema Information
#
# Table name: echoes
# Database name: primary
#
#  id            :integer          not null, primary key
#  echoed_at     :datetime         not null
#  is_seed       :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  pulse_id      :integer          not null
#
# Indexes
#
#  index_echoes_on_echoed_at                   (echoed_at)
#  index_echoes_on_grid_hackr_id               (grid_hackr_id)
#  index_echoes_on_is_seed                     (is_seed)
#  index_echoes_on_pulse_id                    (pulse_id)
#  index_echoes_on_pulse_id_and_grid_hackr_id  (pulse_id,grid_hackr_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  pulse_id       (pulse_id => pulses.id)
#
FactoryBot.define do
  factory :echo do
    association :pulse
    association :grid_hackr
    # echoed_at is auto-set by the model
  end
end
