# == Schema Information
#
# Table name: overlay_now_playing
# Database name: primary
#
#  id            :integer          not null, primary key
#  custom_artist :string
#  custom_title  :string
#  is_live       :boolean          default(FALSE)
#  paused        :boolean          default(FALSE), not null
#  started_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  track_id      :integer
#
# Indexes
#
#  index_overlay_now_playing_on_track_id  (track_id)
#
# Foreign Keys
#
#  track_id  (track_id => tracks.id)
#
class OverlayNowPlaying < ApplicationRecord
  self.table_name = "overlay_now_playing"

  # Associations
  belongs_to :track, optional: true

  # Singleton pattern - only one record should exist
  def self.current
    first_or_create!
  end

  def self.set_track!(track, paused: false)
    current.update!(
      track: track,
      custom_title: nil,
      custom_artist: nil,
      started_at: Time.current,
      paused: paused
    )
    broadcast_change!
  end

  def self.set_custom!(title:, artist: nil)
    current.update!(
      track: nil,
      custom_title: title,
      custom_artist: artist,
      started_at: Time.current,
      paused: false
    )
    broadcast_change!
  end

  def self.set_paused!(paused)
    current.update!(paused: paused)
    broadcast_change!
  end

  def self.clear!
    current.update!(
      track: nil,
      custom_title: nil,
      custom_artist: nil,
      started_at: nil,
      paused: false
    )
    broadcast_change!
  end

  # Display helpers
  def display_title
    custom_title.presence || track&.title || "Nothing Playing"
  end

  def display_artist
    custom_artist.presence || track&.artist&.name || ""
  end

  def display_album
    track&.release&.name || ""
  end

  def album_cover_url
    return nil unless track&.release&.cover_image&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      track.release.cover_image,
      only_path: true
    )
  end

  def absolute_album_cover_url(base_url)
    path = album_cover_url
    return nil unless path

    "#{base_url}#{path}"
  end

  def playing?
    track.present? || custom_title.present?
  end

  def as_api_json(base_url: nil)
    {
      playing: playing?,
      title: display_title,
      artist: display_artist,
      album: display_album,
      album_cover: base_url ? absolute_album_cover_url(base_url) : album_cover_url,
      track_id: track_id,
      paused: paused,
      is_live: is_live,
      started_at: started_at&.iso8601
    }
  end

  # Broadcast to overlay channel
  def self.broadcast_change!
    ActionCable.server.broadcast("overlay_updates", {
      type: "now_playing_changed",
      data: current.as_api_json
    })
  end
end
