# == Schema Information
#
# Table name: hackr_log_reads
# Database name: primary
#
#  id            :integer          not null, primary key
#  read_at       :datetime         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  hackr_log_id  :integer          not null
#
# Indexes
#
#  index_hackr_log_reads_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_log_reads_on_hackr_log_id   (hackr_log_id)
#  index_hackr_log_reads_unique            (grid_hackr_id,hackr_log_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  hackr_log_id   (hackr_log_id => hackr_logs.id)
#
class HackrLogRead < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :hackr_log

  validates :grid_hackr_id, uniqueness: {scope: :hackr_log_id}
  before_validation :set_read_at, on: :create

  def self.record!(hackr, log)
    find_or_create_by!(grid_hackr: hackr, hackr_log: log) { |r| r.read_at = Time.current }
  rescue ActiveRecord::RecordNotUnique
    find_by!(grid_hackr: hackr, hackr_log: log)
  end

  private

  def set_read_at
    self.read_at ||= Time.current
  end
end
