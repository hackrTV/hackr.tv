# == Schema Information
#
# Table name: hackr_streams
# Database name: primary
#
#  id         :integer          not null, primary key
#  ended_at   :datetime
#  is_live    :boolean          default(FALSE), not null
#  live_url   :string
#  started_at :datetime
#  title      :string
#  track_slug :string
#  vod_url    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  artist_id  :integer          not null
#
# Indexes
#
#  index_hackr_streams_on_artist_id  (artist_id)
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
class HackrStream < ApplicationRecord
  belongs_to :artist
  belongs_to :track, primary_key: :slug, foreign_key: :track_slug, optional: true

  validates :live_url, presence: true, if: :is_live?
  validates :title, length: {maximum: 255}
  validate :started_at_before_ended_at
  validate :cannot_restart_stream, on: :update

  before_validation :convert_youtube_urls
  after_update_commit :broadcast_stream_status, if: :saved_change_to_is_live?

  scope :live, -> { where(is_live: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Get the current live stream (if any)
  def self.current_live
    live.first
  end

  # Toggle stream live status
  def go_live!(stream_url, stream_title = nil)
    update!(
      is_live: true,
      live_url: stream_url,
      title: stream_title,
      started_at: Time.current
    )
  end

  def end_stream!
    update!(
      is_live: false,
      ended_at: Time.current
    )
  end

  private

  def convert_youtube_urls
    self.live_url = convert_youtube_url(live_url)
    self.vod_url = convert_youtube_url(vod_url)
  end

  def convert_youtube_url(url)
    return url if url.blank?

    # Convert YouTube watch/live URLs to embed URLs
    # Handles: youtube.com/watch?v=VIDEO_ID, youtu.be/VIDEO_ID, youtube.com/live/VIDEO_ID
    youtube_patterns = [
      /youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/,
      /youtu\.be\/([a-zA-Z0-9_-]{11})/,
      /youtube\.com\/live\/([a-zA-Z0-9_-]{11})/
    ]

    youtube_patterns.each do |pattern|
      if url.match?(pattern)
        video_id = url.match(pattern)[1]
        return "https://www.youtube.com/embed/#{video_id}"
      end
    end

    url
  end

  def started_at_before_ended_at
    return if ended_at.blank? || started_at.blank?

    if ended_at < started_at
      errors.add(:ended_at, "must be after started_at")
    end
  end

  def cannot_restart_stream
    # If trying to go live and stream has already been started before
    if is_live? && started_at_was.present? && started_at_changed?
      errors.add(:base, "Cannot restart a stream that has already been used. Create a new stream instead.")
    end
  end

  def broadcast_stream_status
    ActionCable.server.broadcast("stream_status", {
      type: is_live? ? "stream_live" : "stream_ended",
      is_live: is_live?,
      stream: is_live? ? stream_json : nil
    })
  end

  def stream_json
    {
      id: id,
      title: title,
      artist: artist&.name,
      started_at: started_at&.iso8601
    }
  end
end
