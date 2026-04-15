# == Schema Information
#
# Table name: hackr_vod_watches
# Database name: primary
#
#  id              :integer          not null, primary key
#  watched_at      :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer          not null
#  hackr_stream_id :integer          not null
#
# Indexes
#
#  index_hackr_vod_watches_on_grid_hackr_id    (grid_hackr_id)
#  index_hackr_vod_watches_on_hackr_stream_id  (hackr_stream_id)
#  index_hackr_vod_watches_unique              (grid_hackr_id,hackr_stream_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#  hackr_stream_id  (hackr_stream_id => hackr_streams.id)
#
class HackrVodWatch < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :hackr_stream

  validates :grid_hackr_id, uniqueness: {scope: :hackr_stream_id}
  before_validation :set_watched_at, on: :create

  def self.record!(hackr, stream)
    find_or_create_by!(grid_hackr: hackr, hackr_stream: stream) { |r| r.watched_at = Time.current }
  rescue ActiveRecord::RecordNotUnique
    find_by!(grid_hackr: hackr, hackr_stream: stream)
  end

  private

  def set_watched_at
    self.watched_at ||= Time.current
  end
end
