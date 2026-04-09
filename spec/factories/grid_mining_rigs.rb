# == Schema Information
#
# Table name: grid_mining_rigs
# Database name: primary
#
#  id            :integer          not null, primary key
#  active        :boolean          default(FALSE), not null
#  last_tick_at  :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_grid_mining_rigs_on_grid_hackr_id  (grid_hackr_id) UNIQUE
#
FactoryBot.define do
  factory :grid_mining_rig do
    association :grid_hackr
    active { false }
  end
end
