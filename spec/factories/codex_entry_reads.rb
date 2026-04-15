# == Schema Information
#
# Table name: codex_entry_reads
# Database name: primary
#
#  id             :integer          not null, primary key
#  read_at        :datetime         not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  codex_entry_id :integer          not null
#  grid_hackr_id  :integer          not null
#
# Indexes
#
#  index_codex_entry_reads_on_codex_entry_id  (codex_entry_id)
#  index_codex_entry_reads_on_grid_hackr_id   (grid_hackr_id)
#  index_codex_entry_reads_unique             (grid_hackr_id,codex_entry_id) UNIQUE
#
# Foreign Keys
#
#  codex_entry_id  (codex_entry_id => codex_entries.id)
#  grid_hackr_id   (grid_hackr_id => grid_hackrs.id)
#
FactoryBot.define do
  factory :codex_entry_read do
    association :grid_hackr
    association :codex_entry
    read_at { Time.current }
  end
end
