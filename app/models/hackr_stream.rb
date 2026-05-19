# == Schema Information
#
# Table name: hackr_streams
# Database name: primary
#
#  id           :integer          not null, primary key
#  cancelled_at :datetime
#  ended_at     :datetime
#  is_live      :boolean          default(FALSE), not null
#  live_url     :string
#  scheduled_at :datetime
#  started_at   :datetime
#  title        :string
#  track_slug   :string
#  vod_url      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer          not null
#
# Indexes
#
#  index_hackr_streams_on_artist_id     (artist_id)
#  index_hackr_streams_on_scheduled_at  (scheduled_at)
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
class HackrStream < ApplicationRecord
  EXPIRY_WINDOW = 1.hour

  belongs_to :artist
  belongs_to :track, primary_key: :slug, foreign_key: :track_slug, optional: true
  has_many :hackr_vod_watches, dependent: :destroy

  validates :live_url, presence: true, if: :is_live?
  validates :title, length: {maximum: 255}
  validate :started_at_before_ended_at
  validate :cannot_restart_stream, on: :update

  before_validation :convert_youtube_urls
  after_update_commit :broadcast_stream_status, if: -> {
    saved_change_to_is_live? || saved_change_to_scheduled_at? || saved_change_to_cancelled_at?
  }

  scope :live, -> { where(is_live: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :upcoming, -> {
    where(is_live: false, cancelled_at: nil, ended_at: nil)
      .where.not(scheduled_at: nil)
      .where("scheduled_at > ?", EXPIRY_WINDOW.ago)
      .order(scheduled_at: :asc)
  }
  scope :past_broadcasts, -> {
    where.not(started_at: nil)
      .where(is_live: false)
      .order(started_at: :desc)
  }

  def self.current_live
    live.first
  end

  def self.next_scheduled
    upcoming.first
  end

  def go_live!(stream_url, stream_title = nil)
    update!(
      is_live: true,
      live_url: stream_url,
      title: stream_title || title,
      started_at: Time.current
    )
  end

  def end_stream!
    update!(
      is_live: false,
      ended_at: Time.current
    )
  end

  def cancel!
    if is_live?
      errors.add(:base, "Cannot cancel a live stream")
      raise ActiveRecord::RecordInvalid, self
    end
    update!(cancelled_at: Time.current)
  end

  def display_state
    return :live if is_live?
    return :cancelled if cancelled_at.present?
    return :ended if ended_at.present?
    return :expired if expired?
    return :starting_soon if starting_soon?
    return :upcoming if scheduled_at.present?
    :unscheduled
  end

  def starting_soon?
    scheduled_at.present? && scheduled_at <= Time.current &&
      scheduled_at > EXPIRY_WINDOW.ago && !is_live? && ended_at.nil? && cancelled_at.nil?
  end

  def expired?
    scheduled_at.present? && scheduled_at <= EXPIRY_WINDOW.ago &&
      !is_live? && ended_at.nil? && cancelled_at.nil?
  end

  def stream_json
    {
      id: id,
      title: title,
      artist: artist&.name,
      started_at: started_at&.iso8601
    }
  end

  def scheduled_json
    {
      id: id,
      title: title,
      artist: artist&.name,
      artist_slug: artist&.slug,
      scheduled_at: scheduled_at&.iso8601,
      display_state: display_state.to_s
    }
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
    # Prevent re-going-live on a stream that has already ended
    if is_live? && !is_live_was && ended_at_was.present?
      errors.add(:base, "Cannot restart a stream that has already ended. Create a new stream instead.")
    end
  end

  def broadcast_stream_status
    next_stream = HackrStream.includes(:artist).next_scheduled
    ActionCable.server.broadcast("stream_status", {
      type: broadcast_type,
      is_live: is_live?,
      stream: is_live? ? stream_json : nil,
      next_scheduled: next_stream&.scheduled_json
    })
  end

  def broadcast_type
    return "stream_live" if saved_change_to_is_live? && is_live?
    return "stream_ended" if saved_change_to_is_live? && !is_live?
    "scheduled_stream_updated"
  end
end
