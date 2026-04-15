# == Schema Information
#
# Table name: hackr_radio_tunes
# Database name: primary
#
#  id               :integer          not null, primary key
#  tuned_at         :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  grid_hackr_id    :integer          not null
#  radio_station_id :integer          not null
#
# Indexes
#
#  index_hackr_radio_tunes_on_grid_hackr_id     (grid_hackr_id)
#  index_hackr_radio_tunes_on_radio_station_id  (radio_station_id)
#  index_hackr_radio_tunes_unique               (grid_hackr_id,radio_station_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id     (grid_hackr_id => grid_hackrs.id)
#  radio_station_id  (radio_station_id => radio_stations.id)
#
class HackrRadioTune < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :radio_station

  validates :grid_hackr_id, uniqueness: {scope: :radio_station_id}
  before_validation :set_tuned_at, on: :create

  def self.record!(hackr, station)
    find_or_create_by!(grid_hackr: hackr, radio_station: station) { |r| r.tuned_at = Time.current }
  rescue ActiveRecord::RecordNotUnique
    find_by!(grid_hackr: hackr, radio_station: station)
  end

  private

  def set_tuned_at
    self.tuned_at ||= Time.current
  end
end
