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
class CodexEntryRead < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :codex_entry

  validates :grid_hackr_id, uniqueness: {scope: :codex_entry_id}
  before_validation :set_read_at, on: :create

  def self.record!(hackr, entry)
    find_or_create_by!(grid_hackr: hackr, codex_entry: entry) { |r| r.read_at = Time.current }
  rescue ActiveRecord::RecordNotUnique
    find_by!(grid_hackr: hackr, codex_entry: entry)
  end

  private

  def set_read_at
    self.read_at ||= Time.current
  end
end
