# == Schema Information
#
# Table name: grid_hackr_track_plays
# Database name: primary
#
#  id              :integer          not null, primary key
#  first_played_at :datetime         not null
#  play_count      :integer          default(1), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer          not null
#  track_id        :integer          not null
#
# Indexes
#
#  index_grid_hackr_track_plays_on_grid_hackr_id  (grid_hackr_id)
#  index_grid_hackr_track_plays_on_track_id       (track_id)
#  index_track_plays_unique                       (grid_hackr_id,track_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  track_id       (track_id => tracks.id)
#
class GridHackrTrackPlay < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :track

  validates :grid_hackr_id, uniqueness: {scope: :track_id}
  before_validation :set_first_played_at, on: :create

  # Upsert: on first call, creates row with play_count=1.
  # Subsequent calls increment play_count and return the record.
  def self.record!(hackr, track)
    record = find_or_initialize_by(grid_hackr: hackr, track: track)
    if record.new_record?
      record.first_played_at = Time.current
      record.play_count = 1
      record.save!
    else
      record.increment!(:play_count)
    end
    record
  rescue ActiveRecord::RecordNotUnique
    # Concurrent insert race — fetch the winning row and increment it.
    record = find_by!(grid_hackr: hackr, track: track)
    record.increment!(:play_count)
    record
  end

  private

  def set_first_played_at
    self.first_played_at ||= Time.current
  end
end
